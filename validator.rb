class Validator
  def self.valid_page(name)
    # TODO: uniqueness
    unless name.nil? || name == '' || name == 'new'
      true
    end
  end
end
