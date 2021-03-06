class ItemsController < ApplicationController
  #rescue_from ActionController::RedirectBackError, with: :redirect_to_default
  include SqlQueryBuilder
  layout 'main/main'

  before_action :dropdowns, :only => [:new_query, :new, :edit]
  protect_from_forgery :except => :populate_items
  
  autocomplete :items, :catalog_nr
  autocomplete :items, :company_name
  autocomplete :items, :item_description

  # Turn off strong parameters for this controller (due to dynamic naming of items array)
  def params
    request.parameters
  end

  def new_query
    @item_query = ItemQuery.new(:from_date => (Date.today - 30).beginning_of_month,
                                :to_date   =>  Date.today)
  end
  
  def list_selected
    @item_query = ItemQuery.new(params[:item_query])
    
    if @item_query.valid?
      condition_array = define_conditions(params)
      items_all = Item.find_all_by_date(condition_array)
      items_notordered = items_all.reject{|item| item.ordered?}
     
      # Eliminate items from array, based on order status if specified
      if params[:item_query][:ordered_status] && params[:item_query][:ordered_status] != 'All'
        @items = items_notordered                        if params[:item_query][:ordered_status] == 'NotOrdered'
        @items = items_all.reject{|item| !item.ordered?} if params[:item_query][:ordered_status] == 'Ordered' 
      else
        @items = items_all
      end

      if params[:order]
        # Check whether any potential items to order, and if so, populate company drop-down
        @items_to_order = items_notordered.size
        @companies = list_companies_from_items(items_notordered)
        render :action => :order_item_list
      elsif params[:receive]
        render :action => :receive_item_list
      else  #params[:submit]
        render :action => :index
      end
      
    else
      dropdowns
      render :action => :new_query
    end
  end
  
  def list_unordered_items
    @items = Item.find_all_unordered
    @items_to_order = @items.size
    @companies = list_companies_from_items(@items)
    render :action => :index
  end
  
  # GET /items
  def index
    @items = Item.find_all_by_date
    
    items_notordered = @items.reject{|item| item.ordered?}
    @items_to_order = items_notordered.size
    @companies = list_companies_from_items(items_notordered)  
  end

  # GET /items/1
  def show
    @item = Item.find(params[:id])
  end

  # GET /items/new
  def new
    requester = (current_user.researcher ? current_user.researcher.researcher_name : nil)
    @item_default = Item.new(:requester_name => requester)
  end

  def populate_items
    @items = []
    params[:nr_items] ||= 3

    0.upto(params[:nr_items].to_i - 1) do |i|
        @items[i] = Item.new(:requester_name => params[:item_default][:requester_name],
                           :deliver_site => params[:item_default][:deliver_site],
                           :grant_nr => params[:item_default][:grant_nr])
    end
    respond_to do |format|
      format.js
    end
  end

  # GET /items/1/edit
  def edit
    @item = Item.find(params[:id])
  end

  # POST /items
  def create         
    # items should ideally be in an array params[:items], but workaround to have the auto-populate after the auto-complete
    # on the multi-item form, with html tags identified => item params are instead in params[:items_1], params[:items_2] etc.
    
    # Loop around params[:items_1] to params[:items_n], merge defaults into each item, and create array
    @items = []
    for i in 0..25 do
      this_item = params['items_' + i.to_s]
      break if this_item.nil?
      next  if (param_blank?(this_item[:item_description]) && param_blank?(this_item[:catalog_nr]))
      @items.push(Item.new(this_item))
    end
    
    #@email_create_orders = email_value(EMAIL_CREATE, 'orders', @items[0].deliver_site.downcase)
    #@email_delivery_orders = email_value(EMAIL_DELIVERY, 'orders', @items[0].deliver_site.downcase)
    #render :action => 'debug'
    
    if @items.all?(&:valid?) 
      @items.each(&:save!)
      flash[:notice] = 'Items were successfully saved.'
      
      # item successfully saved => send emails as indicated by EMAIL_CREATE and EMAIL_DELIVERY flags
      email_create_orders = email_value(EMAIL_CREATE, 'orders', @items[0].deliver_site)
      email_delivery_orders = email_value(EMAIL_DELIVERY, 'orders', @items[0].deliver_site)
      
      email = OrderMailer.new_items(@items, current_user) unless email_create_orders == 'NoEmail'
      if email_delivery_orders == 'Debug'
        render(:text => "<pre>" + email.encoded + "</pre>")
      else
        email.deliver! if email_delivery_orders == 'Deliver'
        redirect_to :action => 'list_unordered_items'
      end
         
    else
      reload_defaults(params[:item_default])
      flash.now[:error] = 'One or more errors - no items saved, please enter all required fields'
      render :action => 'new'
    end 

  end

  # PUT /items/1
  def update
    params[:item][:company_name] ||= params[:other_company]
    @item = Item.find(params[:id])

    if @item.update_attributes(params[:item])
      flash[:notice] = 'Item was successfully updated.'
      #redirect_to(@item)
      redirect_to :action => 'new_query'
    else
      dropdowns
      render :action => "edit", :other_company => params[:other_company]
    end
  end

  def receive_items
    Item.where("id in (?)",params[:item_id]).update_all(:item_received => 'Y')
    flash[:notice] = 'Items were successfully received'
    redirect_to :action => 'new_query'
  end

  # DELETE /items/1
  def destroy
    @item = Item.find(params[:id])
    @item.destroy

    redirect_to :action => 'new_query'
  end

  def export_items
    export_type = 'T'
    @items = Item.find_for_export(params[:export_id])
    file_basename = ['LIMS_Items', Date.today.to_s].join("_")

    case export_type
      when 'T'  # Export to tab-delimited text using csv_string
        @filename = file_basename + '.txt'
        csv_string = export_items_csv(@items)
        send_data(csv_string,
                  :type => 'text/csv; charset=utf-8; header=present',
                  :filename => @filename, :disposition => 'attachment')

      else # Use for debugging
        csv_string = export_items_csv(@items)
        render :text => csv_string
    end
  end

  def autocomplete_for_catalog_nr
    @items = Item.find_all_unique(["catalog_nr LIKE ?", params[:term] + '%'])
    list = @items.map {|i| Hash[ id: i.id, label: i.catalog_nr, name: i.catalog_nr, company_name: i.company_name, desc: i.item_description, price: i.item_price ]}
    render json: list
  end
  
  def autocomplete_for_item_description
    @items = Item.find_all_unique(["item_description LIKE ?", params[:term] + '%'])
    list = @items.map {|i| Hash[ id: i.id, label: i.item_description, name: i.item_description, cat_nr: i.catalog_nr, company_name: i.company_name, price: i.item_price]}
    render json: list
  end
  
  def autocomplete_for_company_name
    @items = Item.find_all_unique(["company_name LIKE ?", params[:term] + '%'])
    @items = @items.uniq { |h| h[:company_name] }
    list = @items.map {|i| Hash[ id: i.id, label: i.company_name, name: i.company_name]}
    render json: list
  end
  
  def update_fields
    params[:i] ||= 0
    if params[:catalog_nr]
      @item = Item.find_by_catalog_nr(params[:catalog_nr])
    elsif params[:item_description]
      @item = Item.find_by_item_description(params[:item_description]) 
    end
    
    if @item.nil?
      render :nothing => true
    else
      render :update do |page|
        page['items_' + params[:i] + '_catalog_nr'].value        = @item.catalog_nr
        page['items_' + params[:i] + '_item_description'].value  = @item.item_description
        page['items_' + params[:i] + '_company_name'].value      = @item.company_name
        page['items_' + params[:i] + '_chemical_flag'].value     = @item.chemical_flag
        page['items_' + params[:i] + '_item_size'].value         = @item.item_size
        page['items_' + params[:i] + '_item_price'].value        = @item.item_price
       end
    end
  end
  
protected
  def dropdowns
    items_all  = Item.all
    @companies = list_companies_from_items(items_all)
    @requestors = items_all.collect(&:requester_name).sort.uniq
    @researchers = Researcher.populate_dropdown
    @grant_nrs = Category.populate_dropdown_for_category('grants')
  end
  
  def reload_defaults(item_params)
    dropdowns
    @item_default    = Item.new(item_params)
  end

  def list_companies_from_items(items)
    companies_from_items = items.collect(&:company_name).sort.uniq
    return ["CWA"] | companies_from_items | ["Other"]
  end
  
  def define_conditions(params)
    @where_select, @where_values = build_sql_where(params[:item_query], ItemQuery::QUERY_FLDS, [], [])

    if !param_blank?(params[:item_query][:order_received_flag])
      # Filtering for order received='N' should also return records where order received is blank or partial
      recv_flag = params[:item_query][:order_received_flag]
      recv_condition = (['Y','P'].include?(recv_flag) ? "= '#{recv_flag}'" : "<> 'Y'")
      @where_select.push("orders.order_received #{recv_condition}")
    end

    if !param_blank?(params[:item_query][:item_received_flag])
      # Filtering for order received='N' should also return records where order received is blank or partial
      recv_flag = params[:item_query][:item_received_flag]
      recv_condition = (recv_flag == 'N' ? "<> 'Y'" : "= '#{recv_flag}'")
      @where_select.push("items.item_received #{recv_condition}")
    end

    date_fld = 'items.created_at'
    @where_select, @where_values = sql_conditions_for_date_range(@where_select, @where_values, params[:item_query], date_fld)

    return sql_where_clause(@where_select, @where_values)
   end

  def redirect_to_default
    redirect_to root_path
  end

  def export_items_csv(items)
    hdgs, flds = export_items_setup

    csv_string = CSV.generate(:col_sep => "\t") do |csv|
      csv << hdgs

      items.each do |item|
        item_xref = model_xref(item)
        fld_array    = []

        flds.each do |obj_code, fld|
          obj = item_xref[obj_code.to_sym]
          if obj
            fld_array << nil_if_blank(obj.send(fld))
          else
            fld_array << nil
          end
        end
        csv << [Date.today.to_s].concat(fld_array)
      end
    end
    return csv_string
  end

  def export_items_setup
    hdgs  = %w{DownloadDt OrderDt RPO_CWA Requisition Order Site Requester ItemDt Description Company CatalogNr Chemicals?
               Size Qty Price ExtPrice Received? GrantNr Notes}

    flds   = [['od', 'date_ordered'],
              ['od', 'rpo_or_cwa'],
              ['od', 'po_number'],
              ['od', 'order_number'],
              ['im', 'deliver_site'],
              ['im', 'requester_abbrev'],
              ['im', 'created_at'],
              ['im', 'item_description'],
              ['im', 'company_name'],
              ['im', 'catalog_nr'],
              ['im', 'chemical_flag'],
              ['im', 'item_size'],
              ['im', 'item_quantity'],
              ['im', 'item_price'],
              ['im', 'item_ext_price'],
              ['im', 'item_received'],
              ['im', 'grant_nr'],
              ['im', 'notes']]

    return hdgs, flds
  end

  def model_xref(item)
    item_xref = {:od => item.order,
                 :im => item}
    return item_xref
  end

end
