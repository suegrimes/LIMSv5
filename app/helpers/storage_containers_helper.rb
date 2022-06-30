module StorageContainersHelper
  def grid_coords(row,col,display_format,max_col)
    coords = nil
    if display_format == '2D'
      coords = [col,row].join("")
    elsif display_format == '2Dseq'
      coords = ((row.to_i - 1) * max_col.to_i + col.to_i).to_s
    end
    return coords
  end
end