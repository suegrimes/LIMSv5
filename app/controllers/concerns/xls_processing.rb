module XlsProcessing
  extend ActiveSupport::Concern

  # use Roo gem to open a csv, xls or xlsx file
  def open_spreadsheet(file)
    logger.debug "open_spreadsheet: file.tempfile: #{file.tempfile}"
    ss = nil
    case File.extname(file.original_filename)
      when '.csv'
        ss = Roo::Csv.new(file.tempfile)
        @input_type = "csv"
      # for some reason Roo fails to open an IO opbect but can use the file path
      when '.ods'
        ss = Roo::OpenOffice.new(file.tempfile.path)
        @input_type = "ods"
      when '.xlsx'
        ss = Roo::Excelx.new(file.tempfile)
        @input_type = "xlsx"
      else nil
    end
    return ss
  end

# set the default sheet index
def set_sheet_index(index)
  @sh_index = index
end

# get the default sheet index
def get_sheet_index()
  @sh_index
end

# return an array of column header names
# we assume headers are in the first row (count starting from 1)
# this should work wether the default sheet is set or not
def get_header
  @ss.sheet(@sh_index).row(1)
end

def cur_sheet_name
  @ss.sheets[@sh_index]
end

def get_row(row_index)
  @ss.sheet(@sh_index).row(row_index)
end

# if spreadsheet return a capitalized column label
def column_id(col_index)
  return col_index if @input_type == "csv"
  if col_index < 26
    return (('A'.ord) + col_index).chr
  else
    x = (col_index - 1) / 26
    y = col_index % 26
    a = (('A'.ord) + x).chr
    b = (('A'.ord) + y).chr
    return a + b
  end
end

# return hash with sheet name symbols as keys and sheet indexes as values
  def sheets_to_process(given, expected)
    map = {}
    given.each_with_index do |sh, i|
      cl = sh.downcase.to_sym
      if expected.include?(cl)
        map[cl] = i
      end
    end
    return map
  end
end
