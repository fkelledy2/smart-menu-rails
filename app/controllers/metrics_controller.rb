class MetricsController < ApplicationController
  before_action :set_metric, only: %i[ index show edit update destroy ]

  # GET /metrics or /metrics.json
  def index
    @metrics = Metric.all
  end

  # GET /metrics/1 or /metrics/1.json
  def show
  end

  # GET /metrics/new
  def new
    @metric = Metric.new
  end

  # GET /metrics/1/edit
  def edit
  end

  # POST /metrics or /metrics.json
  def create
    @metric = Metric.new(metric_params)

    respond_to do |format|
      if @metric.save
        format.html { redirect_to metric_url(@metric), notice: "Metric was successfully created." }
        format.json { render :show, status: :created, location: @metric }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @metric.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /metrics/1 or /metrics/1.json
  def update
    respond_to do |format|
      if @metric.update(metric_params)
        format.html { redirect_to metric_url(@metric), notice: "Metric was successfully updated." }
        format.json { render :show, status: :ok, location: @metric }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @metric.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /metrics/1 or /metrics/1.json
  def destroy
    @metric.destroy!

    respond_to do |format|
      format.html { redirect_to metrics_url, notice: "Metric was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_metric
      Metric.delete_all
      @metric = Metric.new()
      @metric.numberOfRestaurants = Restaurant.count
      @metric.numberOfMenus = Menu.count
      @metric.numberOfMenuItems = Menuitem.count
      @metric.numberOfOrders = Ordr.count
      @metric.totalOrderValue = Ordr.all.sum(:gross)
      @metric.save

#       if Plan.count > 0
#           FeaturesPlan.delete_all
#           User.all.each do |user|
#               user.plan = nil;
#               user.save
#           end
#           Userplan.delete_all
#           Plan.delete_all
#           Feature.delete_all
      if Plan.count == 0
          @feature1 = Feature.new()
          @feature1.key = "feature1.key"
          @feature1.descriptionKey = "feature1.description"
          @feature1.status = 0
          @feature1.save

          @feature2 = Feature.new()
          @feature2.key = "feature2.key"
          @feature2.descriptionKey = "feature2.description"
          @feature2.status = 0
          @feature2.save

          @feature3 = Feature.new()
          @feature3.key = "feature3.key"
          @feature3.descriptionKey = "feature3.description"
          @feature3.status = 0
          @feature3.save

          @feature4 = Feature.new()
          @feature4.key = "feature4.key"
          @feature4.descriptionKey = "feature4.description"
          @feature4.status = 0
          @feature4.save

          @feature5 = Feature.new()
          @feature5.key = "feature5.key"
          @feature5.descriptionKey = "feature5.description"
          @feature5.status = 0
          @feature5.save

          @feature6 = Feature.new()
          @feature6.key = "feature6.key"
          @feature6.descriptionKey = "feature6.description"
          @feature6.status = 0
          @feature6.save

          @starter = Plan.new()
          @starter.key = "plan.starter.key"
          @starter.descriptionKey = "plan.starter.description"
          @starter.attribute1 = "plan.starter.attribute1"
          @starter.attribute2 = "plan.starter.attribute2"
          @starter.attribute3 = "plan.starter.attribute3"
          @starter.attribute4 = "plan.starter.attribute4"
          @starter.attribute5 = "plan.starter.attribut5"
          @starter.attribut6 = "plan.starter.attribut6"
          @starter.status = 0
          @starter.favourite = false
          @starter.pricePerMonth = 29
          @starter.pricePerYear = 290
          @starter.menusperlocation = 1
          @starter.itemspermenu = 50
          @starter.languages = 1
          @starter.locations = 1
          @starter.action = 0
          @starter.save

          @pro = Plan.new()
          @pro.key = "plan.pro.key"
          @pro.descriptionKey = "plan.pro.description"
          @pro.attribute1 = "plan.pro.attribute1"
          @pro.attribute2 = "plan.pro.attribute2"
          @pro.attribute3 = "plan.pro.attribute3"
          @pro.attribute4 = "plan.pro.attribute4"
          @pro.attribute5 = "plan.pro.attribute5"
          @pro.attribut6 = "plan.pro.attribut6"
          @pro.status = 0
          @pro.favourite = true
          @pro.pricePerMonth = 79
          @pro.pricePerYear = 790
          @pro.menusperlocation = 3
          @pro.itemspermenu = 100
          @pro.languages = 4
          @pro.locations = 3
          @pro.action = 0
          @pro.save


          @business = Plan.new()
          @business.key = "plan.business.key"
          @business.descriptionKey = "plan.business.description"
          @business.attribute1 = "plan.business.attribute1"
          @business.attribute2 = "plan.business.attribute2"
          @business.attribute3 = "plan.business.attribute3"
          @business.attribute4 = "plan.business.attribute4"
          @business.attribute5 = "plan.business.attribute5"
          @business.attribut6 = "plan.business.attribut6"
          @business.status = 0
          @business.favourite = false
          @business.pricePerMonth = 149
          @business.pricePerYear = 1490
          @business.menusperlocation = 5
          @business.itemspermenu = 200
          @business.languages = 10
          @business.locations = 10
          @business.action = 0
          @business.save

          @enterprise = Plan.new()
          @enterprise.key = "plan.enterprise.key"
          @enterprise.descriptionKey = "plan.enterprise.description"
          @enterprise.attribute1 = "plan.enterprise.attribute1"
          @enterprise.attribute2 = "plan.enterprise.attribute2"
          @enterprise.attribute3 = "plan.enterprise.attribute3"
          @enterprise.attribute4 = "plan.enterprise.attribute4"
          @enterprise.attribute5 = "plan.enterprise.attribute5"
          @enterprise.attribut6 = "plan.enterprise.attribut6"
          @enterprise.status = 0
          @enterprise.menusperlocation = -1
          @enterprise.itemspermenu = -1
          @enterprise.languages = -1
          @enterprise.locations = -1
          @enterprise.favourite = false
          @enterprise.action = 1
          @enterprise.save

#           @feature1Plan1 = FeaturesPlan.new()
#           @feature1Plan1.feature = @feature1
#           @feature1Plan1.plan = @trial
#           @feature1Plan1.featurePlanNote = "feature1.trial.note"
#           @feature1Plan1.status = 0
#           @feature1Plan1.save
#           @feature1Plan2 = FeaturesPlan.new()
#           @feature1Plan2.feature = @feature1
#           @feature1Plan2.plan = @pro
#           @feature1Plan2.featurePlanNote = "feature1.pro.note"
#           @feature1Plan2.status = 0
#           @feature1Plan2.save
#           @feature1Plan3 = FeaturesPlan.new()
#           @feature1Plan3.feature = @feature1
#           @feature1Plan3.plan = @enterprise
#           @feature1Plan3.featurePlanNote = "feature1.enterprise.note"
#           @feature1Plan3.status = 0
#           @feature1Plan3.save
#
#           @feature2Plan1 = FeaturesPlan.new()
#           @feature2Plan1.feature = @feature2
#           @feature2Plan1.plan = @trial
#           @feature2Plan1.featurePlanNote = "feature2.trial.note"
#           @feature2Plan1.status = 0
#           @feature2Plan1.save
#           @feature2Plan2 = FeaturesPlan.new()
#           @feature2Plan2.feature = @feature2
#           @feature2Plan2.plan = @pro
#           @feature2Plan2.featurePlanNote = "feature2.pro.note"
#           @feature2Plan2.status = 0
#           @feature2Plan2.save
#           @feature2Plan3 = FeaturesPlan.new()
#           @feature2Plan3.feature = @feature2
#           @feature2Plan3.plan = @enterprise
#           @feature2Plan3.featurePlanNote = "feature2.enterprise.note"
#           @feature2Plan3.status = 0
#           @feature2Plan3.save
#
#           @feature3Plan2 = FeaturesPlan.new()
#           @feature3Plan2.feature = @feature3
#           @feature3Plan2.plan = @pro
#           @feature3Plan2.featurePlanNote = "feature3.pro.note"
#           @feature3Plan2.status = 0
#           @feature3Plan2.save
#           @feature3Plan3 = FeaturesPlan.new()
#           @feature3Plan3.feature = @feature3
#           @feature3Plan3.plan = @enterprise
#           @feature3Plan3.featurePlanNote = "feature3.enterprise.note"
#           @feature3Plan3.status = 0
#           @feature3Plan3.save
#
#           @feature4Plan1 = FeaturesPlan.new()
#           @feature4Plan1.feature = @feature4
#           @feature4Plan1.plan = @trial
#           @feature4Plan1.featurePlanNote = "feature4.trial.note"
#           @feature4Plan1.status = 0
#           @feature4Plan1.save
#           @feature4Plan2 = FeaturesPlan.new()
#           @feature4Plan2.feature = @feature4
#           @feature4Plan2.plan = @pro
#           @feature4Plan2.featurePlanNote = "feature4.pro.note"
#           @feature4Plan2.status = 0
#           @feature4Plan2.save
#           @feature4Plan3 = FeaturesPlan.new()
#           @feature4Plan3.feature = @feature4
#           @feature4Plan3.plan = @enterprise
#           @feature4Plan3.featurePlanNote = "feature4.enterprise.note"
#           @feature4Plan3.status = 0
#           @feature4Plan3.save
#
#
#           @feature5Plan2 = FeaturesPlan.new()
#           @feature5Plan2.feature = @feature5
#           @feature5Plan2.plan = @pro
#           @feature5Plan2.featurePlanNote = "feature5.pro.note"
#           @feature5Plan2.status = 0
#           @feature5Plan2.save
#           @feature5Plan3 = FeaturesPlan.new()
#           @feature5Plan3.feature = @feature5
#           @feature5Plan3.plan = @enterprise
#           @feature5Plan3.featurePlanNote = "feature5.enterprise.note"
#           @feature5Plan3.status = 0
#           @feature5Plan3.save
#
#           @feature6Plan3 = FeaturesPlan.new()
#           @feature6Plan3.feature = @feature6
#           @feature6Plan3.plan = @enterprise
#           @feature6Plan3.featurePlanNote = "feature6.enterprise.note"
#           @feature6Plan3.status = 0
#           @feature6Plan3.save

      end
    end

    # Only allow a list of trusted parameters through.
    def metric_params
      params.fetch(:metric, {})
    end
end
