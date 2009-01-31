atom_feed(:url => formatted_reserves_url(:atom)) do |feed|
  if @user
    feed.title t('reserve.user_reserve', :login_name => @user.login)
  else
    feed.title t('reserve.library_group_reserve', :library_group.display_name => @library_group.display_name)
  end
  feed.updated(@reserves.first ? @reserves.first.created_at : Time.zone.now)

  for reserve in @reserves
    feed.entry(reserve) do |entry|
      entry.title(reserve.manifestation.original_title)
    end
  end
end
