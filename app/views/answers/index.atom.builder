atom_feed(:url => formatted_answers_url(:atom)) do |feed|
  if @user
    feed.title t('answer.user_answer', :login_name => @user.login)
  else
    feed.title t('answer.library_group_answer', :library_group_name => @library_group.display_name)
  end
  feed.updated(@answers.first ? @answers.first.created_at : Time.zone.now)

  for answer in @answers
    feed.entry(answer) do |entry|
      entry.title(truncate(answer.body))
      entry.author(answer.user.login)
      entry.content(answer.body)
    end
  end
end
