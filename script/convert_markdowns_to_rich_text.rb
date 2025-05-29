#!/usr/bin/env ruby

require_relative "../config/environment"
require "redcarpet"
require "nokogiri"

class ActionText::Markdown < ApplicationRecord
  belongs_to :record, polymorphic: true
end

class MarkdownToActionTextConverter
  ATTACHMENT_URL_REGEX = %r{/u/(?<slug>[^\/\s\)]+)}

  def initialize(html)
    @doc = Nokogiri::HTML::DocumentFragment.parse(html)
    @attachments = []
  end

  def convert
    process_images
    process_links
    [ @doc.to_html, @attachments ]
  end

  private
    def process_images
      @doc.css("img").each do |img|
        src = img["src"].presence
        if src && match = src.match(ATTACHMENT_URL_REGEX)
          if (attachment = find_attachment(match[:slug]))
            img.replace(build_attachment_node(attachment))
            @attachments << attachment
          end
        end
      end
    end

    def process_links
      @doc.css("a").each do |link|
        href = link["href"].presence

        if href && match = href.match(ATTACHMENT_URL_REGEX)
          if (attachment = find_attachment(match[:slug]))
            link.replace(build_attachment_node(attachment))
            @attachments << attachment
          end
        end
      end
    end

    def build_attachment_node(attachment)
      html = ActionText::Attachment.from_attachable(attachment).to_html
      fragment = Nokogiri::HTML::DocumentFragment.parse(html)

      node = fragment.at_css("action-text-attachment")
      node["url"] = Rails.application.routes.url_helpers.rails_blob_path(attachment.blob, only_path: true)

      fragment
    end

    def find_attachment(slug)
      ActiveStorage::Attachment.find_by(slug: slug)
    end
end

class RedcarpetRenderer
  def self.render(markdown)
    renderer = Redcarpet::Render::HTML.new
    markdowner = Redcarpet::Markdown.new(renderer,
      autolink: true,
      tables: true,
      fenced_code_blocks: true,
      strikethrough: true,
      superscript: true,
    )
    markdowner.render(markdown.to_s)
  end
end

ApplicationRecord.with_each_tenant do |tenant|
  puts "Processing tenant: #{tenant}"

  ActionText::Markdown.find_each do |markdown|
    next unless markdown.record

    html = RedcarpetRenderer.render(markdown.content.to_s)
    converter = MarkdownToActionTextConverter.new(html)
    rich_text_html, attachments = converter.convert

    rich_text = ActionText::RichText.create!(
      name: markdown.name,
      record: markdown.record,
      body: rich_text_html
    )

    attachments.each do |attachment|
      attachment.update!(record: rich_text)
    end

    puts "✓ Created rich text for #{markdown.record_type}##{markdown.record_id} (#{markdown.name})"
  rescue => e
    warn "✗ Failed to process markdown ##{markdown.id}: #{e.class} - #{e.message}"
  end
end
