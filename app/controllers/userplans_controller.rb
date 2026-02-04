class UserplansController < ApplicationController
  before_action :authenticate_user!
  before_action :set_userplan, only: %i[show edit update destroy]

  # Pundit authorization
  after_action :verify_authorized, except: [:index]
  after_action :verify_policy_scoped, only: [:index]

  # GET /userplans or /userplans.json
  def index
    @userplans = policy_scope(Userplan).limit(100) # Use limit for memory safety, since pagination gem is not installed
  end

  # GET /userplans/1 or /userplans/1.json
  def show
    authorize @userplan
  end

  # GET /userplans/new
  def new
    @userplan = Userplan.new
    authorize @userplan
  end

  # GET /userplans/1/edit
  def edit
    authorize @userplan
    @plans = Plan.display_order
  end

  # POST /userplans or /userplans.json
  def create
    @userplan = Userplan.new(userplan_params)
    authorize @userplan

    respond_to do |format|
      if @userplan.save
        @user = User.where(id: @userplan.user.id).first
        @user.plan = @userplan.plan
        @user.save
        format.html do
          redirect_to root_path, notice: t('common.flash.created', resource: t('activerecord.models.userplan'))
        end
        format.json { render :show, status: :created, location: @userplan }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @userplan.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /userplans/1 or /userplans/1.json
  def update
    authorize @userplan

    respond_to do |format|
      if @userplan.update(userplan_params)
        @user = User.where(id: @userplan.user.id).first
        @user.plan = @userplan.plan
        @user.save
        format.html do
          redirect_to edit_userplan_path(@userplan),
                      notice: t('common.flash.updated', resource: t('activerecord.models.userplan'))
        end
        format.json { render :show, status: :ok, location: @userplan }
      else
        @plans = Plan.display_order
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @userplan.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /userplans/1 or /userplans/1.json
  def destroy
    authorize @userplan
    @userplan.destroy!

    respond_to do |format|
      format.html do
        redirect_to userplans_path, status: :see_other,
                                    notice: t('common.flash.deleted', resource: t('activerecord.models.userplan'))
      end
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_userplan
    @userplan = Userplan.find(params[:id])
    @plans = Plan.display_order
  end

  # Only allow a list of trusted parameters through.
  def userplan_params
    params.require(:userplan).permit(:user_id, :plan_id)
  end
end
