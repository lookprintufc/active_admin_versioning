require "spec_helper"
require "support/with_initializer"
require "support/example_show_resource_attribute"

describe "integration test", type: :feature do
  def random_word
    "string".scan(/\w/).shuffle.join
  end

  def create_post(title = random_word, body = random_word)
    fill_in "post_title", with: title
    fill_in "post_body",  with: body
    click_button "Create Post"
  end

  def update_post(title = random_word, body = random_word)
    fill_in "post_title", with: title
    fill_in "post_body",  with: body
    click_button "Update Post"
  end

  let(:post) { Post.first }
  let(:current_version) { post.versions.last }

  describe "visit page of resource is enabled paper_trail" do
    before do
      visit "/admin/posts/new"
      create_post

      click_link "Edit Post"
      update_post
    end

    describe "viewable registered content" do
      it "should have elements are registered by dsl" do
        within ".action_items" do
          page.should have_link "Version", href: versions_admin_post_path(1)
        end

        within "#sidebar" do
          page.should have_css "#version_sidebar_section"
          page.should have_selector "#version_sidebar_section h3", text: "Version"
          page.should have_selector "tr.row-version td",   text: post.versions.size
          page.should have_selector "tr.row-event td",     text: current_version.event
          page.should have_selector "tr.row-whodunnit td", text: current_version.whodunnit
        end
      end
    end

    describe "viewable versions page" do
      before { click_link "Version" }

      it "should have content" do
        post.versions.each do |version|
          within "#paper_trail_version_#{version.id}" do
            page.should have_selector "td.col-id",        text: version.id
            page.should have_selector "td.col-whodunnit", text: version.whodunnit
            page.should have_selector "td.col-event",     text: version.event
            page.should have_selector "td.col-item_type", text: version.item_type
          end
        end
      end
    end
  end


  describe "when whodunnit_attribute_name is redefined in initializer" do
    include_context :with_initializer

    before do
      allow_any_instance_of(PaperTrail::Version)
          .to receive(whodunnit_attribute_name) { whodunnit_formatted }
    end

    let(:whodunnit_formatted) do
      "User: #{current_version.whodunnit}"
    end


    before do
      visit "/admin/posts/new"
      create_post

      click_link "Edit Post"
      update_post
    end

    describe "sidebar" do
      it "should display alternative whodunnit" do
        within "#sidebar" do
          page.should have_selector "tr.row-whodunnit td", text: whodunnit_formatted, exact: true
        end
      end
    end

    describe "viewable versions page" do
      before { click_link "Version" }

      it "should display alternative whodunnit" do
        post.versions.each do |version|
          within "#paper_trail_version_#{version.id}" do
            page.should have_selector "td.col-whodunnit", text: whodunnit_formatted, exact: true
          end
        end
      end
    end

  end


  describe 'visit resource show-page' do

    let(:title_on_create) { 'title-on-create' }
    let(:title_on_first_update) { 'title-on-update-1' }
    let(:title_on_second_update) { 'title-on-update-2' }

    before do
      visit "/admin/posts/new"
      create_post(title_on_create)
    end

    context 'after create action' do
      include_examples :example_show_resource_attribute do
        let(:expected_title) { title_on_create }
      end
    end

    context 'updates' do
      before do
        click_link "Edit Post"
        update_post(title_on_first_update)
      end

      context 'after first update' do
        include_examples :example_show_resource_attribute do
          let(:expected_title) { title_on_first_update }
        end
      end

      context 'after second update' do
        before do
          click_link "Edit Post"
          update_post(title_on_second_update)
        end

        include_examples :example_show_resource_attribute do
          let(:expected_title) { title_on_second_update }
        end
      end

    end

  end

end
