# frozen_string_literal: true

module Admin
  class LocalGuidesController < ApplicationController
    before_action :authenticate_user!
    before_action :set_local_guide, only: %i[show edit update destroy approve archive regenerate]

    after_action :verify_authorized

    def index
      authorize LocalGuide
      @local_guides = policy_scope(LocalGuide).order(updated_at: :desc)

      if params[:status].present? && LocalGuide.statuses.key?(params[:status])
        @local_guides = @local_guides.where(status: params[:status])
      end
    end

    def show
      authorize @local_guide
    end

    def new
      @local_guide = LocalGuide.new
      authorize @local_guide
    end

    def create
      @local_guide = LocalGuide.new(local_guide_params)
      authorize @local_guide

      if @local_guide.save
        redirect_to admin_local_guide_path(@local_guide), notice: 'Guide created as draft.'
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      authorize @local_guide
    end

    def update
      authorize @local_guide

      if @local_guide.update(local_guide_params)
        redirect_to admin_local_guide_path(@local_guide), notice: 'Guide updated.'
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      authorize @local_guide
      @local_guide.destroy!
      redirect_to admin_local_guides_path, notice: 'Guide deleted.', status: :see_other
    end

    def approve
      authorize @local_guide
      @local_guide.update!(
        status: :published,
        published_at: Time.current,
        approved_by_user_id: current_user.id,
      )
      redirect_to admin_local_guide_path(@local_guide), notice: 'Guide published.'
    end

    def archive
      authorize @local_guide
      @local_guide.update!(status: :archived)
      redirect_to admin_local_guide_path(@local_guide), notice: 'Guide archived.'
    end

    def regenerate
      authorize @local_guide
      LocalGuideGeneratorJob.perform_later(local_guide_id: @local_guide.id)
      redirect_to admin_local_guide_path(@local_guide), notice: 'Regeneration queued.'
    end

    private

    def set_local_guide
      @local_guide = LocalGuide.find(params[:id])
    end

    def local_guide_params
      params.require(:local_guide).permit(:title, :city, :country, :category, :content, :content_source)
    end
  end
end
