# frozen_string_literal: true

require 'icalendar'
require 'icalendar/tzinfo'

class DemoBookingMailer < ApplicationMailer
  DEMOS_EMAIL = 'demos@mellow.menu'
  DEMO_DURATION_MINUTES = 30

  # Sends a branded confirmation to the prospect after they submit the demo
  # booking form. CCs the internal demos inbox and attaches an ICS calendar
  # invite so both parties can add it to their calendars right away.
  def confirmation(demo_booking)
    @demo_booking = demo_booking
    @calendly_url = demo_booking.calendly_booking_url
    @placeholder_start = placeholder_start_time(demo_booking.created_at || Time.current)
    @placeholder_end   = @placeholder_start + DEMO_DURATION_MINUTES.minutes
    @google_cal_url    = google_calendar_url(@demo_booking, @placeholder_start, @placeholder_end)

    attachments['demo_booking.ics'] = {
      mime_type: 'text/calendar; method=REQUEST',
      content: ics_content(demo_booking, @placeholder_start, @placeholder_end),
    }

    mail(
      to: demo_booking.email,
      cc: DEMOS_EMAIL,
      subject: "Your mellow.menu demo — #{demo_booking.contact_name}",
    )
  end

  private

  # Returns 10:00 UTC two business days after the booking date.
  def placeholder_start_time(from)
    day = from.utc.to_date
    business_days_added = 0
    loop do
      day += 1
      business_days_added += 1 unless day.saturday? || day.sunday?
      break if business_days_added >= 2
    end
    Time.utc(day.year, day.month, day.day, 10, 0, 0)
  end

  def ics_content(demo_booking, dtstart, dtend)
    cal = Icalendar::Calendar.new
    cal.prodid = '-//mellow.menu//Demo Booking//EN'
    cal.append_custom_property('METHOD', 'REQUEST')

    event = Icalendar::Event.new
    event.uid         = "demo-booking-#{demo_booking.id || SecureRandom.uuid}@mellow.menu"
    event.dtstart     = Icalendar::Values::DateTime.new(dtstart.strftime('%Y%m%dT%H%M%SZ'))
    event.dtend       = Icalendar::Values::DateTime.new(dtend.strftime('%Y%m%dT%H%M%SZ'))
    event.summary     = "mellow.menu Demo \u2014 #{demo_booking.contact_name}"
    event.description = demo_description(demo_booking)
    event.url         = demo_url(host: default_url_options[:host] || 'www.mellow.menu')

    event.organizer = Icalendar::Values::CalAddress.new(
      "mailto:#{DEMOS_EMAIL}",
      cn: 'mellow.menu Demos',
    )

    attendee_opts = { rsvp: 'TRUE', role: 'REQ-PARTICIPANT', partstat: 'NEEDS-ACTION', cutype: 'INDIVIDUAL' }
    event.append_attendee(
      Icalendar::Values::CalAddress.new("mailto:#{DEMOS_EMAIL}", attendee_opts.merge(cn: 'mellow.menu Demos')),
    )
    event.append_attendee(
      Icalendar::Values::CalAddress.new("mailto:#{demo_booking.email}", attendee_opts.merge(cn: demo_booking.contact_name)),
    )

    cal.add_event(event)
    cal.to_ical
  end

  def demo_description(demo_booking)
    host = default_url_options[:host] || 'www.mellow.menu'
    <<~DESC.strip
      Hi #{demo_booking.contact_name},

      This is a placeholder calendar hold for your mellow.menu demo.
      We will confirm the exact time and send a calendar update shortly.

      Restaurant: #{demo_booking.restaurant_name}

      Book or reschedule your slot:
      #{demo_booking.calendly_booking_url}

      Or visit: https://#{host}/demo

      Looking forward to speaking with you!
      — The mellow.menu team
    DESC
  end

  def google_calendar_url(demo_booking, dtstart, dtend)
    params = {
      action: 'TEMPLATE',
      text: "mellow.menu Demo \u2014 #{demo_booking.contact_name}",
      dates: "#{dtstart.strftime('%Y%m%dT%H%M%SZ')}/#{dtend.strftime('%Y%m%dT%H%M%SZ')}",
      details: "Placeholder hold — time will be confirmed.\nBook your slot: #{demo_booking.calendly_booking_url}",
      location: 'Video call (link to follow)',
    }
    "https://calendar.google.com/calendar/render?#{params.to_query}"
  end
end
