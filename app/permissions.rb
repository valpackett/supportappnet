module Permissions
  def owns_page?
    !@me.nil? && @page.author_adn_id == @me['id']
  end

  def can_vote?(entry)
    !@me.nil? && entry['user']['id'] != @me['id']
  end

  def can_archive_suggestion?
    !@me.nil? && @page.author_adn_id == @me['id']
  end

  def can_delete_suggestion?
    !@me.nil? && @entry['user']['id'] == @me['id']
  end
end
