module SqlQueryBuilder
  extend ActiveSupport::Concern

def sql_compound_condition(sql_fld, fld_vals, fld_ranges)
  where_select = []; where_values = [];

  if !fld_vals.empty?
    where_select.push("#{sql_fld} IN (?)")
    #where_values.push(fld_vals, fld_vals)
    where_values.push(fld_vals)
  end

  if !fld_ranges.empty?
    for fld_range in fld_ranges
      where_select.push("#{sql_fld} BETWEEN ? AND ?")
      where_values.push(fld_range[0], fld_range[1])
    end
  end

  where_clause = (where_select.size > 0 ? ['(' + where_select.join(' OR ') + ')'] : [])
  return where_clause, where_values
end

def sql_compound_condition2(sql_flds, fld_vals, fld_ranges)
  where_select = []; where_values = [];

  if !fld_vals.empty?
    where_select.push("#{sql_flds[0]} IN (?) OR #{sql_flds[1]} IN (?)")
    where_values.push(fld_vals, fld_vals)
  end

  if !fld_ranges.empty?
    for fld_range in fld_ranges
      where_select.push("#{sql_flds[0]} BETWEEN ? AND ? OR #{sql_flds[1]} BETWEEN ? AND ?")
      where_values.push(fld_range[0], fld_range[1], fld_range[0], fld_range[1])
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
  elsif input_val.is_a?(Array) && input_val.size > 1
    input_val.shift if input_val[0].blank?
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
