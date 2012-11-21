module Permissions
  def owns_page?
    @page.author_adn_id == @me['id']
  end

  def can_vote?(entry)
    entry['user']['id'] != @me['id']
  end

  def can_archive_suggestion?
    @page.author_adn_id == @me['id']
  end

  def can_delete_suggestion?
    @entry['user']['id'] == @me['id']
  end
end
