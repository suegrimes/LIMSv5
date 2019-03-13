module SqlQueryBuilder
  extend ActiveSupport::Concern

  def build_sql_where(params, query_fields, where_select, where_values)
    query_fields['standard'].each do |sqltable, sql_attr|
      sql_attr.each do |attr|
        if params.has_key?(attr.to_sym)
          attr_val = sql_value(params[attr.to_sym])
          unless attr_val.blank?
            where_select.push("#{sqltable}.#{attr}" + sql_condition(attr_val) )
            where_values.push(attr_val)
          end
        end
      end
    end

    query_fields['multi_range'].each do |fld, fld_dtls|
        if params.has_key?(fld.to_sym) and !params[fld.to_sym].blank?
          tmp_select, tmp_values   = sql_compound_condition(fld_dtls[:sql_attr],params[fld.to_sym], fld_dtls)
          where_select.push(tmp_select)
          where_values.push(*tmp_values)
        end
    end
    return where_select, where_values
  end  #build_sql_where

  def sql_compound_condition(sql_flds, param_val, fld_dtls)
    where_select = []; where_values = [];
    sql_flds = [*sql_flds]  #Might be single field or array; if character string convert to array

    str_prefix = (fld_dtls.has_key?(:str_prefix) ? fld_dtls[:str_prefix] : '')
    str_pad_len = (fld_dtls.has_key?(:pad_len) ? fld_dtls[:pad_len] : nil)
    fld_vals, fld_ranges, errors = compound_string_params(str_prefix, str_pad_len, param_val)
    #puts "Processing parameter for SQL fld(s): #{sql_flds}"
    #puts fld_vals.inspect, fld_ranges.inspect

    if !fld_vals.empty?
      fld_in = sql_flds.map{|fld| fld + " IN (?)"}
      where_select.push(fld_in.join(' OR '))
      (0..(sql_flds.length-1)).each do #Repeat range for number of sql_fields provided
        where_values.push(fld_vals)
      end
    end

    if !fld_ranges.empty?
      for fld_range in fld_ranges
        fld_between = sql_flds.map{|fld| fld + " BETWEEN ? AND ?"}
        where_select.push(fld_between.join(' OR '))
        (0..(sql_flds.length-1)).each do #Repeat range for number of sql_fields provided
          where_values.push(*fld_range)
        end
      end
    end

    where_clause = (where_select.size > 0 ? ['(' + where_select.join(' OR ') + ')'] : [])
    return where_clause, where_values
  end

def sql_condition(input_val)
  if input_val.is_a?(Array)
    conditional = ' IN (?)'
  elsif input_val.is_a?(String)
    conditional = (input_val[0,4] == 'LIKE'? ' LIKE ?' : ' = ?')
  else
    conditional = ' = ?'
  end
  return conditional
end

def sql_value(input_val)
  if input_val.is_a?(String) && input_val[0,4] == 'LIKE'
    input_val = ['%',input_val[5..-1],'%'].join
  # Hack to deal with Rails 3.2 'error', adding additional blank value to array when multi-item select uses 'Include Blank' value
  #elsif input_val.is_a?(Array) && input_val.size > 1
  elsif input_val.is_a?(Array)
    input_val.reject! { |val| val.blank? }
  end
  return input_val
end

def sql_conditions_for_range(where_select, where_values, from_val, to_val, db_fld)
  if !from_val.blank? && !to_val.blank?
    where_select.push "#{db_fld} BETWEEN ? AND ?"
    where_values.push(from_val, to_val)
  elsif !from_val.blank? # To value is null or blank
    where_select.push("#{db_fld} >= ?")
    where_values.push(from_val)
  elsif !to_val.blank? # From value is null or blank
    where_select.push("(#{db_fld} IS NULL OR #{db_fld} <= ?)")
    where_values.push(to_val)
  end
  return where_select, where_values
end

def sql_conditions_for_date_range(where_select, where_values, params, db_fld)
  if !params[:from_date].blank? && !params[:to_date].blank?
    where_select.push "#{db_fld} BETWEEN ? AND DATE_ADD(?, INTERVAL 1 DAY)"
    where_values.push(params[:from_date], params[:to_date])
  elsif !params[:from_date].blank? # To Date is null or blank
    where_select.push("#{db_fld} >= ?")
    where_values.push(params[:from_date])
  elsif !params[:to_date].blank? # From Date is null or blank
    where_select.push("(#{db_fld} IS NULL OR #{db_fld} <= DATE_ADD(?, INTERVAL 1 DAY))")
    where_values.push(params[:to_date])
  end
  return where_select, where_values
end

def sql_where(condition_array)
  # Handle change from Rails 2.3 to Rails 3.2 to turn conditions into individual parameters vs array
  if condition_array.nil? || condition_array.empty?
    return nil
  else
    return *condition_array
  end
end
end
