# frozen_string_literal: true

class GuidesController < ApplicationController
  skip_before_action :authenticate_user!, raise: false
  skip_before_action :set_current_employee, raise: false
  skip_before_action :set_permissions, raise: false
  skip_before_action :redirect_to_onboarding_if_needed, raise: false

  def index
    @guides = LocalGuide.published.order(published_at: :desc)
    @page_title = 'Local Restaurant Guides | mellow.menu'
    @page_description = 'AI-powered local guides to the best restaurants. Grounded in real menu data.'
    @canonical_url = 'https://www.mellow.menu/guides'
    @og_title = @page_title
    @og_description = @page_description
    @og_url = @canonical_url
  end

  def show
    @guide = LocalGuide.published.find_by!(slug: params[:slug])
    set_guide_meta_tags
    set_guide_schema_org
  rescue ActiveRecord::RecordNotFound
    render file: Rails.public_path.join('404.html'), status: :not_found, layout: false
  end

  private

  def set_guide_meta_tags
    @page_title = "#{@guide.title} | mellow.menu"
    @page_description = @guide.content.to_s.truncate(160, separator: ' ')
    @canonical_url = "https://www.mellow.menu/guides/#{@guide.slug}"
    @og_title = @page_title
    @og_description = @page_description
    @og_url = @canonical_url
  end

  def set_guide_schema_org
    schema = {
      '@context' => 'https://schema.org',
      '@type' => 'Article',
      'headline' => @guide.title,
      'datePublished' => @guide.published_at&.iso8601,
      'dateModified' => @guide.updated_at&.iso8601,
      'publisher' => { '@type' => 'Organization', 'name' => 'mellow.menu' },
    }

    if @guide.faq_data.present? && @guide.faq_data.any?
      schema['mainEntity'] = {
        '@type' => 'FAQPage',
        'mainEntity' => @guide.faq_data.map do |faq|
          {
            '@type' => 'Question',
            'name' => faq['question'],
            'acceptedAnswer' => { '@type' => 'Answer', 'text' => faq['answer'] },
          }
        end,
      }
    end

    @schema_org_json_ld = JSON.generate(schema)
  end
end
