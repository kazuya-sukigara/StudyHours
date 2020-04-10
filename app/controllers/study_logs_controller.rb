class StudyLogsController < ApplicationController
  before_action :authenticate_user!,except: [:show]

  def show
    @study_log = StudyLog.find(params[:id])
    @study_log_comments = @study_log.study_log_comments.all
    @study_log_comment = @study_log.study_log_comments.new
  end

  def new
    @study_log = current_user.study_logs.new
    @study_log.study_log_details.build
  end

  def create
    @study_log = current_user.study_logs.new(study_log_params)
    if @study_log.save
      flash[:notice] = "登録が完了しました。この調子で頑張りましょう"
      redirect_to timelines_path
    else
      render 'new'
    end
  end

  def edit
    @study_log = StudyLog.find(params[:id])
  end

  def update
    @study_log = StudyLog.find(params[:id])
    if @study_log.update(study_log_update_params)
      flash[:notice] = "更新が完了しました。"
      redirect_to study_log_path(@study_log)
    else
      render 'edit'
    end
  end

  def destroy
    study_log = StudyLog.find(params[:id])
    study_log.destroy
    flash[:notice] = "投稿を削除しました。"
    redirect_to timelines_path
  end


private
  def study_log_params
    params.require(:study_log).permit(:working_date,:memo,study_log_details_attributes:[:tag_list,:hour,:min])
  end

  # update内で自分のレコードを判定させるためにidを持たせる
  def study_log_update_params
    params.require(:study_log).permit(:working_date,:memo,study_log_details_attributes:[:tag_list,:hour,:min,:id,:_destroy])
  end

end


