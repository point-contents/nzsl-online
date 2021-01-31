# frozen_string_literal: true

class FeedbackController < ApplicationController
  before_action :find_vocab_sheet, :set_search_query, :footer_content
  invisible_captcha honeypot: :captcha, on_spam: :set_form_spam_flag

  def new
    @feedback = Feedback.new
  end

  def create
    process_feedback

    @feedback = Feedback.new unless @spam
    @page = Page.find(params[:page_id].to_i)
    @title = @page.title

    render template: "pages/#{@page.template}"
  end

  private

  def process_feedback
    feedback = Feedback.create(feedback_params)

    if feedback.valid? && !@spam_flag
      feedback.send_email
      flash.now[:feedback_notice] = t('feedback.success')
    else
      if feedback.valid? && @spam_flag
        flash.now[:feedback_notice] = t('feedback.success')
      else
        flash.now[:feedback_error] = t('feedback.failure')
      end
    end
  rescue StandardError
    flash.now[:feedback_error] = t('feedback.failure')
  end

  def feedback_params
    params.require(:feedback).permit(:name, :message, :video, :email)
  end

  # Custom call back for the Invisible captcha,
  # is there a more Ruby way to do this?
  def set_form_spam_flag
    @spam_flag = true
  end
end
