class UserplansController < ApplicationController
  before_action :set_userplan, only: %i[ show edit update destroy ]

  # GET /userplans or /userplans.json
  def index
    @userplans = Userplan.limit(100) # Use limit for memory safety, since pagination gem is not installed
  end

  # GET /userplans/1 or /userplans/1.json
  def show
  end

  # GET /userplans/new
  def new
    @userplan = Userplan.new
  end

  # GET /userplans/1/edit
  def edit
    @plans = Plan.all
  end

  # POST /userplans or /userplans.json
  def create
    @userplan = Userplan.new(userplan_params)

    respond_to do |format|
      if @userplan.save
        @user = User.where( id: @userplan.user.id).first
        @user.plan = @userplan.plan
        @user.save
        format.html { redirect_to root_path, notice: t('userplans.controller.created') }
        format.json { render :show, status: :created, location: @userplan }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @userplan.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /userplans/1 or /userplans/1.json
  def update
    respond_to do |format|
      if @userplan.update(userplan_params)
        @user = User.where( id: @userplan.user.id).first
        @user.plan = @userplan.plan
        @user.save
        format.html { redirect_to @userplan, notice: t('userplans.controller.updated') }
        format.json { render :show, status: :ok, location: @userplan }
      else
        @plans = Plan.all
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @userplan.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /userplans/1 or /userplans/1.json
  def destroy
    @userplan.destroy!

    respond_to do |format|
      format.html { redirect_to userplans_path, status: :see_other, notice: t('userplans.controller.deleted') }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_userplan
      @userplan = Userplan.find(params[:id])
      @plans = Plan.all
    end

    # Only allow a list of trusted parameters through.
    def userplan_params
      params.require(:userplan).permit(:user_id, :plan_id)
    end
end
