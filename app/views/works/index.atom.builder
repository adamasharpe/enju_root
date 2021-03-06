atom_feed(:url => works_url(:format => :atom)) do |feed|
  feed.title t('work.library_group_work', :library_group_name => @library_group.display_name.localize)
  feed.updated(@works.first ? @works.first.created_at : Time.zone.now)

  @works.each do |work|
    feed.entry(work) do |entry|
      entry.title(work.original_title)

      work.patrons.each do |patron|
        entry.author do |author|
          author.name(patron.full_name)
        end
      end
    end
  end
end
