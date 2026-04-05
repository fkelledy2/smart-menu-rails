# frozen_string_literal: true

module TwoFactor
  # Generates a TOTP secret for a user and returns the QR code SVG and provisioning URI.
  # Does NOT persist anything — call BackupCodeService and persist via the controller.
  class SetupService
    ISSUER = 'mellow.menu'

    def initialize(user)
      @user = user
    end

    # Returns { secret:, qr_svg:, provisioning_uri: }
    def call
      secret = ROTP::Base32.random
      totp = ROTP::TOTP.new(secret, issuer: ISSUER)
      provisioning_uri = totp.provisioning_uri(@user.email)

      qrcode = RQRCode::QRCode.new(provisioning_uri)
      qr_svg = qrcode.as_svg(
        offset: 0,
        color: '000',
        shape_rendering: 'crispEdges',
        module_size: 4,
        standalone: true,
      )

      { secret: secret, qr_svg: qr_svg, provisioning_uri: provisioning_uri }
    end

    private

    attr_reader :user
  end
end
