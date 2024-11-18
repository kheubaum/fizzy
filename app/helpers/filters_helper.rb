module FiltersHelper
  def filter_chip_tag(text, params)
    link_to bubbles_path(params), class: "btn txt-small btn--remove" do
      concat tag.span(text)
      concat image_tag("close.svg", aria: { hidden: true }, size: 24)
    end
  end

  def filter_hidden_field_tag(key, value)
    name = params[key].is_a?(Array) ? "#{key}[]" : key
    hidden_field_tag name, value, id: nil
  end
end
