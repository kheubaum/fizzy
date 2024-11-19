module WorkflowsHelper
  def link_to_stage_picker(bubble, workflow)
    link_to workflow.name, new_bucket_bubble_stage_picker_path(bubble.bucket, bubble, workflow_id: workflow), class: "btn full-width justify-start borderless workflow-stage"
  end

  def button_to_set_stage(bubble, stage)
    button_to stage.name, bucket_bubble_stagings_path(bubble.bucket, bubble, stage_id: stage),
      method: :post, class: [ "btn full-width justify-start borderless workflow-stage", { "workflow-stage--current": stage == bubble.stage } ],
      form_class: "flex align-center gap-half",
      data: { turbo_frame: "_top" }
  end
end
