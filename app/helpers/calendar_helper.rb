module CalendarHelper
  def month_link(month_date)
    link_to(I18n.l(month_date, :format => :only_month), {:month => month_date.month, :year => month_date.year}, :class => 'month_link')
  end
  
  # custom options for this calendar
  def event_calendar_opts
    { 
      :year => @year,
      :month => @month,
      :event_strips => @event_strips,
      :month_name_text => I18n.l(@shown_month, :format => :only_year_and_month),
      :previous_month_text => "<< " + month_link(@shown_month.last_month),
      :next_month_text => month_link(@shown_month.next_month) + " >>"
    }
  end

  def event_calendar
    calendar event_calendar_opts do |event|
      "<a href='/events/#{event.id}' title=\"#{h(event.name)}: #{event.start_at} to #{event.end_at}\"><div>#{h(event.name)} (#{event.library.display_name.localize})</div></a>"
    end
  end
end
