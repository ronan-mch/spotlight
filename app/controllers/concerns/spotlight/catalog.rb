module Spotlight
  ##
  # Spotlight catalog mixins
  module Catalog
    extend ActiveSupport::Concern
    include Blacklight::Catalog
    include Spotlight::Base

    included do
      before_filter do
        if current_exhibit && can?(:curate, current_exhibit)
          blacklight_config.add_facet_field 'exhibit_visibility',
                                            label: I18n.t(:'spotlight.catalog.facets.exhibit_visibility.label'),
                                            query: {
                                              private: {
                                                label: I18n.t(:'spotlight.catalog.facets.exhibit_visibility.private'),
                                                fq: "#{Spotlight::SolrDocument.visibility_field(current_exhibit)}:false" }
                                            }
        end
      end
    end

    def render_save_this_search?
      (current_exhibit && can?(:curate, current_exhibit)) &&
        !(params[:controller] == 'spotlight/catalog' && params[:action] == 'admin')
    end
  end
end
