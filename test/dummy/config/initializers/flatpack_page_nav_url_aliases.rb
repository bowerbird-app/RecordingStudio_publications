# frozen_string_literal: true

# Recording Studio 4.2 default layout passes `anchor_url` / `back_url`.
# Flatpack PageNav understands `anchor_href`. Map the layout close URL so
# action screens can leave through the page that first opened them.
module FlatPackPageNavUrlAliases
  def initialize(**kwargs)
    if kwargs[:anchor_href].blank? && kwargs[:anchor_url].present?
      kwargs[:anchor_href] = kwargs[:anchor_url]
    end
    kwargs.delete(:anchor_url)
    kwargs.delete(:back_url)
    super(**kwargs)
  end
end

Rails.application.config.to_prepare do
  next unless defined?(FlatPack::PageNav::Component)
  next if FlatPack::PageNav::Component.ancestors.include?(FlatPackPageNavUrlAliases)

  FlatPack::PageNav::Component.prepend(FlatPackPageNavUrlAliases)
end
