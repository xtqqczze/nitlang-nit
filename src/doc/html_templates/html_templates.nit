# This file is part of NIT ( http://www.nitlanguage.org ).
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Introduces templates that compose the documentation HTML rendering.
module html_templates

import html_model
import html::bootstrap
import doc_phases::doc_structure
import doc_phases::doc_hierarchies
import doc_phases::doc_graphs
import doc_phases::doc_intros_redefs

# Renders the page as HTML.
redef class DocPage
	super Template

	# Page url.
	var html_url: String is writable, noinit

	# Directory where css, js and other assets can be found.
	var shareurl: String is writable, noinit

	# Attributes of the body tag element.
	var body_attrs = new Array[TagAttribute]

	# Top menu template if any.
	var topmenu: DocTopMenu is writable, noinit

	# Sidebar template if any.
	var sidebar: nullable DocSideBar = null is writable

	# Content of the page in form a TplSection.
	# TODO remove when other templates are migrated.
	var sections = new Array[TplSection]

	# Footer content if any.
	var footer: nullable Writable = null is writable

	# JS scripts to append at the end of the body
	var scripts = new Array[TplScript]

	# Adds a section to this page.
	# TODO remove when other templates are migrated.
	fun add_section(section: TplSection) do
		sections.add section
	end

	# Renders the html `<head>`.
	private fun render_head do
		var css = (self.shareurl / "css").html_escape
		var vendors = (self.shareurl / "vendors").html_escape

		addn "<!DOCTYPE html>"
		addn "<head>"
		addn " <meta charset='utf-8'/>"
		addn " <!--link rel='stylesheet' href='{css}/Nitdoc.UI.css' type='text/css'/-->"
		addn " <link rel='stylesheet' href='{vendors}/bootstrap/css/bootstrap.min.css'/>"
		addn " <link rel='stylesheet' href='{css}/nitdoc.bootstrap.css'/>"
		addn " <link rel='stylesheet' href='{css}/nitdoc.css'/>"
		addn " <link rel='stylesheet' href='{css}/Nitdoc.QuickSearch.css'/>"
		addn " <link rel='stylesheet' href='{css}/Nitdoc.ModalBox.css'/>"
		addn " <link rel='stylesheet' href='{css}/Nitdoc.GitHub.css'/>"
		addn " <title>{title.html_escape}</title>"
		addn "</head>"
		add "<body"
		for attr in body_attrs do add attr
		addn ">"
	end

	# Renders the footer and content.
	private fun render_content do
		for section in sections do add section
		if footer != null then
			addn "<div class='well footer'>"
			add footer.as(not null)
			addn "</div>"
		end
	end

	# Render JS scripts
	private fun render_footer do
		var vendors = (self.shareurl / "vendors").html_escape
		var js = (self.shareurl / "js").html_escape

		addn "<script src='{vendors}/jquery/jquery-1.11.1.min.js'></script>"
		addn "<script src='{vendors}/jquery/jquery-ui-1.10.4.custom.min.js'></script>"
		addn "<script src='{vendors}/bootstrap/js/bootstrap.min.js'></script>"
		addn "<script data-main='{js}/nitdoc' src='{js}/lib/require.js'></script>"
		for script in scripts do add script
		addn """<script>
			$(function () {
				$("[data-toggle='tooltip']").tooltip();
				$("[data-toggle='popover']").popover();
			});
		</script>"""
		addn "</body>"
		addn "</html>"
	end

	# Render the whole page
	redef fun rendering do
		render_head
		addn "<div class='container-fluid'>"
		addn " <div class='row'>"
		add topmenu
		addn " </div>"
		addn " <div class='row' id='content'>"
		var sidebar = self.sidebar
		if sidebar != null then
			addn "<div class='col col-xs-3 col-lg-2'>"
			add sidebar
			addn "</div>"
			addn "<div class='col col-xs-9 col-lg-10' data-spy='scroll' data-target='.summary'>"
			render_content
			addn "</div>"
		else
			addn "<div class='col col-xs-12'>"
			render_content
			addn "</div>"
		end
		addn " </div>"
		addn "</div>"
		render_footer
	end

	# Render table of content for this page.
	fun html_toc: UnorderedList do
		var lst = new UnorderedList
		lst.css_classes.add "nav"
		for child in root.children do
			child.render_toc_item(lst)
		end
		return lst
	end
end

# Top menu bar template.
#
# FIXME should be a Bootstrap component template
# At this moment, the topmenu structure stills to specific to Nitdoc to use the
# generic component.
class DocTopMenu
	super UnorderedList

	# Brand link to display in first position of the top menu.
	#
	# This is where you want to put your logo.
	var brand: nullable Writable is noinit, writable

	# Active menu item.
	#
	# Depends on the current page, this allows to hilighted the current item.
	#
	# FIXME should be using Boostrap breadcrumbs component.
	# This will still like this to avoid diff and be changed in further fixes
	# when we will modify the output.
	var active_item: nullable ListItem is noinit, writable

	redef fun rendering do
		addn "<nav id='topmenu' class='navbar navbar-default navbar-fixed-top' role='navigation'>"
		addn " <div class='container-fluid'>"
		addn "  <div class='navbar-header'>"
		add "   <button type='button' class='navbar-toggle' "
		addn "       data-toggle='collapse' data-target='#topmenu-collapse'>"
		addn "    <span class='sr-only'>Toggle menu</span>"
		addn "    <span class='icon-bar'></span>"
		addn "    <span class='icon-bar'></span>"
		addn "    <span class='icon-bar'></span>"
		addn "   </button>"
		if brand != null then
			add "<span class='navbar-brand'>"
			add brand.write_to_string
			add "</span>"
		end
		addn "  </div>"
		addn "  <div class='collapse navbar-collapse' id='topmenu-collapse'>"
		addn "   <ul class='nav navbar-nav'>"
		for item in items do
			if item == active_item then item.css_classes.add "active"
			add item.write_to_string
		end
		addn "   </ul>"
		addn "  </div>"
		addn " </div>"
		addn "</nav>"
	end
end

# Nitdoc sidebar template.
class DocSideBar
	super Template

	# Sidebar contains `DocSideBox`.
	var boxes = new Array[DocSideBox]

	redef fun rendering do
		if boxes.is_empty then return
		addn "<div id='sidebar'>"
		for box in boxes do add box
		addn "</div>"
	end
end

# Something that can be put in a DocSideBar.
class DocSideBox
	super Template

	# Box HTML id, used for Bootstrap collapsing feature.
	#
	# Use `html_title.to_cmangle` by default.
	var id: String is lazy do return title.write_to_string.to_cmangle

	# Title of the box to display.
	var title: Writable

	# Content to display in the box.
	var content: Writable

	# Is the box opened by default?
	#
	# Otherwise, the user will have to clic on the title to display the content.
	#
	# Default is `true`.
	var is_open = true is writable

	redef fun rendering do
		var open = ""
		if is_open then open = "in"
		addn "<div class='panel'>"
		addn " <div class='panel-heading'>"
		add "  <a data-toggle='collapse' data-parent='#sidebar'"
		add "   data-target='#box_{id}' href='#'>"
		add title
		addn "  </a>"
		addn " </div>"
		addn " <div id='box_{id}' class='summary panel-body collapse {open}'>"
		add content
		addn " </div>"
		addn "</div>"
	end
end

redef class DocComposite
	super Template

	# HTML anchor id
	var html_id: String is noinit

	# Title to display if any.
	#
	# This title can be decorated with HTML.
	var html_title: nullable Writable is noinit, writable

	# Subtitle to display if any.
	var html_subtitle: nullable Writable is noinit, writable

	# Render the element title and subtitle.
	private fun render_title do
		if html_title != null then
			addn new Header(hlvl, html_title.write_to_string)
		end
		if html_subtitle != null then
			addn "<div class='info subtitle'>"
			addn html_subtitle.write_to_string
			addn "</div>"
		end
	end

	# Render the element body.
	private fun render_body do end

	redef fun rendering do
		if is_hidden then return
		render_title
		render_body
	end

	# Level <hX> for HTML heading.
	private fun hlvl: Int do
		if parent == null then return 1
		return parent.hlvl + 1
	end

	# Is `self` not displayed in the page.
	#
	# By default, empty elements are hidden.
	fun is_hidden: Bool do return is_empty

	# A short, undecorated title that goes in the table of contents.
	#
	# By default, returns `html_title.to_s`, subclasses should redefine it.
	var toc_title: String is lazy, writable do return html_title.to_s

	# Is `self` hidden in the table of content?
	var is_toc_hidden = false is writable

	# Render this element in a table of contents.
	private fun render_toc_item(lst: UnorderedList) do
		if is_toc_hidden then return

		var content = new Template
		content.add new Link("#{html_id}", toc_title)

		if not children.is_empty then
			var sublst = new UnorderedList
			sublst.css_classes.add "nav"
			for child in children do
				child.render_toc_item(sublst)
			end
			content.add sublst
		end
		lst.add_li new ListItem(content)
	end
end

redef class DocSection
	super BSComponent

	redef fun rendering do
		if is_hidden then
			addn "<a id=\"{html_id}\"></a>"
			return
		end
		render_body
	end
end

redef class DocArticle
	super BSComponent

	# Never displays the title for article.
	#
	# This is to maintain compatibility with old components, this may change
	# without notice in further version.
	redef fun render_title do end
end

redef class MEntityComposite
	redef var html_id is lazy do return mentity.nitdoc_id
	redef var html_title is lazy do return mentity.nitdoc_name
end

redef class ConcernSection
	redef var html_id is lazy do return "section_concerns_{mentity.nitdoc_id}"
	redef var html_title is lazy do return "in {mentity.nitdoc_name}"
	redef fun is_toc_hidden do return is_empty
end

redef class ImportationListSection
	redef var html_id is lazy do return "section_dependancies_{mentity.nitdoc_id}"
	redef var html_title is lazy do return "Dependencies"
end

redef class InheritanceListSection
	redef var html_id is lazy do return "section_inheritance_{mentity.nitdoc_id}"
	redef var html_title is lazy do return "Inheritance"
end

redef class IntroArticle
	redef var html_id is lazy do return "article_intro_{mentity.nitdoc_id}"
	redef var html_title is lazy do return null
	redef var is_hidden = false
	redef var is_toc_hidden = true

	redef fun render_body do
		var comment = mentity.html_comment
		if comment != null then	addn comment
		super
	end
end

redef class ConcernsArticle
	redef var html_id is lazy do return "article_concerns_{mentity.nitdoc_id}"
	redef var html_title = "Concerns"
	redef fun is_hidden do return concerns.is_empty
	redef fun render_body do add concerns.html_list
end

redef class DefinitionArticle
	redef var html_id is lazy do return "article_definition_{mentity.nitdoc_id}"
	redef var html_title is lazy do return mentity.html_name
	redef var html_subtitle is lazy do return mentity.html_declaration
	redef var is_hidden = false

	redef fun render_body do
		var comment = mentity.html_comment
		if comment != null then	addn comment
		super
	end
end

redef class HierarchyListArticle
	redef var html_id is lazy do return "article_hierarchy_{list_title}_{mentity.nitdoc_id}"
	redef var html_title is lazy do return list_title
	redef fun is_empty do return mentities.is_empty
	redef fun is_toc_hidden do return mentities.is_empty

	redef fun render_body do
		var lst = new UnorderedList
		lst.css_classes.add "list-unstyled list-definition"
		for mentity in mentities do
			lst.add_li mentity.html_list_item
		end
		addn lst
	end
end

redef class IntrosRedefsListArticle
	redef var html_id is lazy do return "article_intros_redefs_{mentity.nitdoc_id}"
	redef var html_title is lazy do return list_title
	redef fun is_hidden do return mentities.is_empty
	redef var is_toc_hidden = true

	redef fun render_body do
		var lst = new UnorderedList
		lst.css_classes.add "list-unstyled list-labeled"
		for mentity in mentities do
			lst.add_li mentity.html_list_item
		end
		add lst
	end
end

redef class GraphArticle
	redef var html_id is lazy do return "article_graph_{mentity.nitdoc_id}"
	redef var html_title = null
	redef var toc_title do return "Graph"
	redef var is_hidden = false
	redef var is_toc_hidden = true

	# HTML map used to display link.
	#
	# This attribute is set by the `doc_render` phase who knows the context.
	var map: String is noinit, writable

	redef fun render_body do
		addn "<div class=\"text-center\">"
		addn " <img src='{id}.png' usemap='#{id}' style='margin:auto'"
		addn "  alt='{graph_title}'/>"
		add map
		addn "</div>"
	end
end
