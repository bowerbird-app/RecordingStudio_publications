# frozen_string_literal: true

class DemoHomeSection < RecordingStudioAdmin::Section
  key "root"
  icon :newspaper
  title "Publications admin demo"
  blast_radius :site

  link :publications,
       text: "Publications",
       url: ->(context) { context.admin_section_path("publications") },
       style: :primary
end
