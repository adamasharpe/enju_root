atom_feed(:url => inter_library_loans_url(:format => :atom)) do |feed|
  feed.title t('inter_library_loan.library_group_inter_library_loan', :library_group_name => @library_group.display_name)
  feed.updated(@inter_library_loans.first ? @inter_library_loans.first.created_at : Time.zone.now)

  for inter_library_loan in @inter_library_loans
    feed.entry(inter_library_loan) do |entry|
      entry.title h(inter_library_loan.item.manifestation.original_title)
      entry.author(@library_group.display_name)
    end
  end
end
