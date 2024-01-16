module NumFormatting
  extend ActiveSupport::Concern
  def int_with_commas(number)
    whole, decimal = number.to_s.split(".")
    num_groups = whole.chars.to_a.reverse.each_slice(3)
    whole_with_commas = num_groups.map(&:join).join(',').reverse
    #[whole_with_commas, decimal].compact.join(".")
  end
end
