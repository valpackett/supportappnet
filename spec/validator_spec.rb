require_relative '../app/validator.rb'

describe Validator do
  it "validates pages" do
    Validator.page_repo = stub(:page_repository)
    Validator.page_repo.should_receive(:find_first_by_name)
    lambda { Validator.valid_page?("", "")        }.should raise_error ValidationException
    lambda { Validator.valid_page?("a", "")       }.should raise_error ValidationException
    lambda { Validator.valid_page?("", "a")       }.should raise_error ValidationException
    lambda { Validator.valid_page?("new", "a")    }.should raise_error ValidationException
    lambda { Validator.valid_page?("docs", "a")   }.should raise_error ValidationException
    Validator.valid_page?("a", "a").should be true
    Validator.page_repo.should_receive(:find_first_by_name).with("exists").and_return(true)
    lambda { Validator.valid_page?("exists", "a") }.should raise_error ValidationException
  end

  it "validates posts" do
    lambda { Validator.valid_post?("", "") }.should raise_error ValidationException
    lambda { Validator.valid_post?("a" * 257, "a" * 257) }.should raise_error ValidationException
    Validator.valid_post?("@myfreeweb hello", "hello").should be true
  end
end
