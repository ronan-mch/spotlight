require 'spec_helper'

module Spotlight
  describe 'spotlight/exhibits/index', type: :view do
    let(:exhibits) { Spotlight::Exhibit.none }
    let(:ability) { ::Ability.new(user) }
    let(:user) { Spotlight::Engine.user_class.new }

    before do
      assign(:exhibits, exhibits)
      allow(view).to receive_messages(exhibit_path: '/', current_user: user, current_ability: ability)
    end

    context 'with published exhibits' do
      let!(:exhibit_a) { FactoryGirl.create(:exhibit, published: true) }
      let!(:exhibit_b) { FactoryGirl.create(:exhibit, published: true) }
      let!(:exhibit_c) { FactoryGirl.create(:exhibit, published: false) }

      let(:exhibits) { Spotlight::Exhibit.all }

      it 'renders the published exhibits' do
        render

        expect(rendered).to have_selector('.exhibit-card', count: 2)
        expect(rendered).to have_text exhibit_a.title
        expect(rendered).to have_text exhibit_b.title
        expect(rendered).not_to have_text exhibit_c.title

        expect(rendered).not_to include 'Private exhibits'
      end

      it 'does not include the tab bar' do
        render

        expect(rendered).not_to have_selector '.nav-tabs'
      end

      context 'with an exhibit admin' do
        let(:user) { FactoryGirl.create(:exhibit_admin) }

        it 'includes a tab with the exhibits curated by the user' do
          render

          expect(rendered).to have_selector '.nav-tabs'
          expect(rendered).to have_link 'Your exhibits'
          expect(rendered).to have_text user.exhibits.first.title
        end

        it 'does not include a tab for unpublished exhibits' do
          render

          expect(rendered).to have_selector '.nav-tabs'
          expect(rendered).not_to have_link 'Unpublished exhibits'
        end
      end

      context 'with a site admin' do
        let(:user) { FactoryGirl.create(:site_admin) }

        before do
          allow(view).to receive_messages(can?: true, new_exhibit_path: '/exhibits/new')
        end

        it 'includes a tab with unpublished exhibits' do
          render

          expect(rendered).to have_selector '.nav-tabs'
          expect(rendered).to have_link 'Unpublished exhibits'
          expect(rendered).to have_text exhibit_c.title
        end
      end
    end

    context 'with an authorized user' do
      let(:user) { FactoryGirl.build(:site_admin) }

      before do
        allow(view).to receive_messages(can?: true,
                                        new_exhibit_path: '/exhibits/new')
      end

      it 'gives instructions for getting started' do
        render

        expect(rendered).to include 'Welcome to Spotlight!'
        expect(rendered).to have_link 'Create Exhibit', href: '/exhibits/new'
      end

      it 'has a sidebar with a button to create a new exhibit' do
        render

        expect(rendered).to have_selector 'aside .btn', text: 'Create a new exhibit'
      end
    end
  end
end
