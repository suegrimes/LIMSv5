module SqlQueryExport
  extend ActiveSupport::Concern

  def export_results_to_csv(query_obj, query_results)
    hdgs = query_obj::EXPORT_FLDS[:hdgs]
    flds = query_obj::EXPORT_FLDS[:flds]

    csv_string = CSV.generate(:col_sep => "\t") do |csv|
      csv << hdgs

      query_results.each do |result_obj|
        fld_array    = []
        obj_xref  = model_xref(result_obj)

        flds.each do |obj_code, fld|
          obj = obj_xref[obj_code.to_sym]
          if obj
            fld_array << obj.send(fld)
          else
            fld_array << nil
          end
        end
        csv << [Date.today.to_s].concat(fld_array)
      end
    end
    return csv_string
  end

  def model_xref(result_obj)
    # Fix this to be general, ..will be different for each query type
    flowcell_xref = {:fc => result_obj}
  end
end
