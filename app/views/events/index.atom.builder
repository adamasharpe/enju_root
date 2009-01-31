atom_feed(:url => formatted_events_url(:atom)) do |feed|
  feed.title t('event.library_group_event', :library_group.display_name => @library_group.display_name)
  feed.updated(@events.first ? @events.first.created_at : Time.zone.now)

  for event in @events
    feed.entry(event) do |entry|
      entry.title(event.title)
    end
  end
end
