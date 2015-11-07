require 'spec_helper'

describe Spotlight::AccessControlsEnforcementSearchBuilder do
  class MockSearchBuilder < Blacklight::SearchBuilder
    attr_reader :blacklight_params, :scope
    def initialize(blacklight_params, scope)
      @blacklight_params = blacklight_params
      @scope = scope
    end
    include Spotlight::AccessControlsEnforcementSearchBuilder
    include Blacklight::Solr::SearchBuilderBehavior

    def blacklight_config
      scope.current_exhibit.blacklight_config
    end
  end

  subject { MockSearchBuilder.new blacklight_params, scope }
  let(:exhibit) { FactoryGirl.create(:exhibit) }
  let(:scope) { double(current_exhibit: exhibit) }
  let(:solr_request) { Blacklight::Solr::Request.new }
  let(:blacklight_params) { Hash.new }

  describe '#apply_permissive_visibility_filter' do
    it 'allows curators to view everything' do
      allow(scope).to receive(:can?).and_return(true)
      subject.apply_permissive_visibility_filter(solr_request)
      expect(solr_request.to_hash).to be_empty
    end

    it 'restricts searches to public items' do
      allow(scope).to receive(:can?).and_return(false)

      subject.apply_permissive_visibility_filter(solr_request)
      expect(solr_request).to include :fq
      expect(solr_request[:fq]).to include '-exhibit_1_public_bsi:false'
    end

    it 'does not filter resources to just those created by the exhibit' do
      allow(subject).to receive(:can?).and_return(true)
      subject.apply_permissive_visibility_filter(solr_request)
      expect(solr_request).to include :fq
      expect(solr_request[:fq]).not_to include "spotlight_exhibit_slug_#{exhibit.slug}_bsi:true"
    end
  end

  describe '#apply_exhibit_resources_filter' do
    context 'with filter_resources_by_exhibit' do
      before do
        allow(Spotlight::Engine.config).to receive(:filter_resources_by_exhibit).and_return(true)
      end

      it 'filters resources to just those created by the exhibit' do
        allow(scope).to receive(:can?).and_return(true)

        subject.apply_exhibit_resources_filter(solr_request)
        expect(solr_request).to include :fq
        expect(solr_request[:fq]).to include "{!term f=spotlight_exhibit_slug_#{exhibit.slug}_bsi}true"
      end
    end
  end
end
