# frozen_string_literal: true

require 'rails_helper'

describe 'stream_entries/show.html.haml', without_verify_partial_doubles: true do
  before do
    double(:api_oembed_url => '')
    double(:account_stream_entry_url => '')
    allow(view).to receive(:show_landing_strip?).and_return(true)
    allow(view).to receive(:site_title).and_return('example site')
    allow(view).to receive(:site_hostname).and_return('example.com')
    allow(view).to receive(:full_asset_url).and_return('//asset.host/image.svg')
    allow(view).to receive(:local_time)
    allow(view).to receive(:local_time_ago)
    assign(:instance_presenter, InstancePresenter.new)
  end

  it 'has valid author h-card and basic data for a detailed_status' do
    alice  =  Fabricate(:account, username: 'alice', display_name: 'Alice')
    bob    =  Fabricate(:account, username: 'bob', display_name: 'Bob')
    status =  Fabricate(:status, account: alice, text: 'Hello World')
    reply  =  Fabricate(:status, account: bob, thread: status, text: 'Hello Alice')

    assign(:status, status)
    assign(:stream_entry, status.stream_entry)
    assign(:account, alice)
    assign(:type, status.stream_entry.activity_type.downcase)
    assign(:descendant_threads, [])

    render

    mf2 = Microformats.parse(rendered)

    expect(mf2.entry.url.to_s).not_to be_empty
    expect(mf2.entry.author.name.to_s).to eq alice.display_name
    expect(mf2.entry.author.url.to_s).not_to be_empty
  end

  it 'has valid h-cites for p-in-reply-to and p-comment' do
    alice   =  Fabricate(:account, username: 'alice', display_name: 'Alice')
    bob     =  Fabricate(:account, username: 'bob', display_name: 'Bob')
    carl    =  Fabricate(:account, username: 'carl', display_name: 'Carl')
    status  =  Fabricate(:status, account: alice, text: 'Hello World')
    reply   =  Fabricate(:status, account: bob, thread: status, text: 'Hello Alice')
    comment =  Fabricate(:status, account: carl, thread: reply, text: 'Hello Bob')

    assign(:status, reply)
    assign(:stream_entry, reply.stream_entry)
    assign(:account, alice)
    assign(:type, reply.stream_entry.activity_type.downcase)
    assign(:ancestors, reply.stream_entry.activity.ancestors(1, bob) )
    assign(:descendant_threads, [{ statuses: reply.stream_entry.activity.descendants(1)}])

    render

    mf2 = Microformats.parse(rendered)

    expect(mf2.entry.url.to_s).not_to be_empty
    expect(mf2.entry.comment.url.to_s).not_to be_empty
    expect(mf2.entry.comment.author.name.to_s).to eq carl.display_name
    expect(mf2.entry.comment.author.url.to_s).not_to be_empty

    expect(mf2.entry.in_reply_to.url.to_s).not_to be_empty
    expect(mf2.entry.in_reply_to.author.name.to_s).to eq alice.display_name
    expect(mf2.entry.in_reply_to.author.url.to_s).not_to be_empty
  end

  it 'has valid opengraph tags' do
    alice   =  Fabricate(:account, username: 'alice', display_name: 'Alice')
    status  =  Fabricate(:status, account: alice, text: 'Hello World')

    assign(:status, status)
    assign(:stream_entry, status.stream_entry)
    assign(:account, alice)
    assign(:type, status.stream_entry.activity_type.downcase)
    assign(:descendant_threads, [])

    render

    header_tags = view.content_for(:header_tags)

    expect(header_tags).to match(%r{<meta content=".+" property="og:title" />})
    expect(header_tags).to match(%r{<meta content="article" property="og:type" />})
    expect(header_tags).to match(%r{<meta content=".+" property="og:image" />})
    expect(header_tags).to match(%r{<meta content="http://.+" property="og:url" />})
  end
end
