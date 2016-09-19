require 'spec_helper'

describe CrawlerUtils do
  
  context "split_license" do
    it "returns list of licenseNames without surrounding spaces" do
      res = CrawlerUtils.split_licenses(['MIT', '  GPL     '])
      expect(res[0]).to eq('MIT')
      expect(res[1]).to eq('GPL')
    end

    it "returns list of licenses after splitting string with ORs" do
      res = CrawlerUtils.split_licenses('(LGPL-2.1 or GPL-3.0+)')
      expect(res).not_to be_nil
      expect(res[0]).to eq('LGPL-2.1')
      expect(res[1]).to eq('GPL-3.0+')
    end

    it "returns list of single license if it was plain string" do
      res = CrawlerUtils.split_licenses('MIT')
      expect(res).not_to be_nil
      expect(res[0]).to eq('MIT')
    end
  end


  it "create_newest" do
    expect(Newest.count).to eq(0)
    product = ProductFactory.create_new
    CrawlerUtils.create_newest product, "1.0.0"
    expect(Newest.count).to eq(1)

    CrawlerUtils.create_newest product, "1.0.0"
    expect(Newest.count).to eq(1)
  end

  it "creates a notification" do
    expect(Notification.count).to eq(0)

    product = ProductFactory.create_new
    user_1 = UserFactory.create_new 1
    user_2 = UserFactory.create_new 2
    product.users << user_1
    product.users << user_2
    created = CrawlerUtils.create_notifications product, "1.0.0"
    expect(created).to eq(2)
    expect(Notification.count).to eq(2)
  end

end
