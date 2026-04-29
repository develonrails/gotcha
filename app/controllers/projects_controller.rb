# frozen_string_literal: true

class ProjectsController < ApplicationController
  def index
    @projects = Project
      .select(
        "gotcha_projects.*",
        "(SELECT COUNT(*) FROM gotcha_error_events WHERE project_id = gotcha_projects.id) AS error_count",
        "(SELECT COUNT(*) FROM gotcha_performance_events WHERE project_id = gotcha_projects.id) AS perf_count"
      )
      .order(:name)
  end

  def new
    @project = Project.new
  end

  def create
    @project = Project.new(project_params)
    if @project.save
      flash_success "Project \"#{@project.name}\" created. DSN: #{@project.dsn}"
      redirect_to projects_path
    else
      flash_error @project.errors.full_messages.join(", ")
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @project = Project.find(params[:id])
    @event_counts = @project.event_counts
  end

  def update
    @project = Project.find(params[:id])
    if @project.update(project_params)
      flash_success "Project \"#{@project.name}\" updated"
      redirect_to @project
    else
      flash_error @project.errors.full_messages.join(", ")
      @event_counts = @project.event_counts
      render :show, status: :unprocessable_entity
    end
  end

  def destroy
    @project = Project.find(params[:id])
    name = @project.name
    @project.destroy
    flash_success "Project \"#{name}\" deleted"
    redirect_to projects_path
  end

  private

  def project_params
    params.require(:project).permit(:name, :platform, :retention_days)
  end
end
