Analytics = Segment::Analytics.new({
    write_key: 'wbCBFYvM4m8eNdpZzwoXVaVPYjXLwSVG',
    on_error: Proc.new { |status, msg| print msg },
    stub: !Rails.env.production?
})