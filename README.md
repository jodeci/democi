[![Gem Version](https://badge.fury.io/rb/democi.svg)](https://badge.fury.io/rb/democi)
[![Code Climate](https://codeclimate.com/github/jodeci/democi/badges/gpa.svg)](https://codeclimate.com/github/jodeci/democi)
[![Test Coverage](https://codeclimate.com/github/jodeci/democi/badges/coverage.svg)](https://codeclimate.com/github/jodeci/democi/coverage)
[![Build Status](https://travis-ci.org/jodeci/democi.svg?branch=master)](https://travis-ci.org/jodeci/democi)

# 來把 rails app 中常用的 view helper 打包成 gem 吧

### 目標

- 把 rails app 的 view helper 打包成 gem
- gem 本身用 rspec 測試
- 串接 Code Climate 和 Travis CI
- 推上 rubygems

由於相關的關鍵字都太 general，組合出來的結果通常不是我在找的東西，踩雷的過程歡樂無比（？），於是決定做個 demo gem 一勞永逸 :fist:

## 打包 gem

這裡有兩種做法，一種是從陽春 gem 開始自幹 railtie，一種是直接做成 mountable rails plugin。以結論來說後者寫起來輕鬆很多，但工程師就是喜歡踩雷自幹，所以還是從這邊開始吧 XD

### 陽春自幹

起手式 `bundle gem democi`，生成如下的空包彈：

```
# projects/democi
.
├── .gitignore
├── .rspec
├── .travis.yml
├── Gemfile
├── LICENSE.txt
├── README.md
├── Rakefile
├── democi.gemspec
├── bin
│   ├── console
│   └── setup
├── lib
│   ├── democi
│   │   └── version.rb
│   └── democi.rb
└── spec
    ├── democi_spec.rb
    └── spec_helper.rb
```

接著改一下 `gemspec`：

```
# democi.gemspec
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "democi/version"

Gem::Specification.new do |spec|
  spec.name = "democi"
  spec.version = Democi::VERSION
  spec.authors = ["Tsehau Chao"]
  spec.email = ["jodeci@5xruby.tw"]

  spec.description = "just a gem for demo"
  spec.summary = "just a gem for demo"
  spec.homepage = "https://github.com/jodeci/democi"
  spec.files = Dir["lib/**/*", "LICENSE.txt", "README.md"]
end
```

由於最終目標是要丟上 Travis CI，順手把 `add_development_dependency` 的 gem 通通移到 `Gemfile`，不然推上去後 Travis CI 會找不到套件：

```
# Gemfile
source "https://rubygems.org"
gemspec

group :test, :development do
  gem "bundler"
  gem "rake"
  gem "rspec"
end
```

確認動作是否正常：

```
$ bundle install
$ gem build democi
$ rake spec
```

### 用 railtie 自幹 helper

如果一開始就乖乖用 mountable rails plugin 來做的話，這邊就不需要這麼麻煩 XD 

先把要打包的功能寫在 `Democi::ViewHelpers`：

```
# lib/democi/view_helpers.rb
module Democi
  module ViewHelpers
  	def demo
  	  "hello, world!"
  	end
  end
end
```

接著透過 `railtie` 讓 rails app 可以使用`Democi::ViewHelpers`：

```
# lib/democi/railtie.rb
require "rails/railtie"
require "democi/view_helpers"
module Democi
  class Railtie < ::Rails::Railtie
    initializer "democi.view_helpers" do
      ActiveSupport.on_load(:action_view) { include Democi::ViewHelpers }
    end
  end
end
```

`railtie.rb` 需要再載入 gem 的主程式：

```
# lib/democi.rb
require "democi/version"
require "democi/railtie"
module Democi
end
```

gemspec 也補一下 dependency：

```
# democi.gemspec
Gem::Specification.new do |spec|
  # ...
  spec.add_dependency "rails", "~> 5.0"
  spec.add_dependency "activesupport", "~> 5.0"
end
```

把目前的進度打進 gem 裡，順便確定一下環境沒有被玩壞：

```
$ bundle install
$ gem build democi
$ rake spec
```

### 拿進 rails app 實測

隨便開一個 rails app，把剛剛打包的 gem 裝進來：

```
# Gemfile
gem "democi", path: "projects/democi" # 先測本機就好
```

隨便找個 view 戳一下我們剛剛包進去的 `demo()` 方法：

```
# view/something.html.erb
<%= demo %>
=> hello, world!
```

恭喜，可以動了！

## 那來補測試吧

這裡有兩個選擇，一個是徹底硬幹，模擬最低限度的 rails 環境，一個是老老實實弄成 rails engine，該有什麼功能就有什麼功能。以本文的範例來說雖然的確可以自幹，但實務上很快就會遇到自幹的極限，所以這邊還是乖乖做成 rails engine 吧。

### 產生 dummy app

找一個不會礙事的地方，產生 plugin 的空包彈：

```
# temp
$ rails plugin new democi --mountable --dummy-path=spec/dummy --skip-test-unit
```

空包彈裡有很多檔案，我們只需要 `spec/dummy` 這個目錄：

```
$ cp -rf temp/democi/spec/dummy projects/spec/dummy
$ rm -rf temp/democi
```

加進測試用的 gem：

```
# Gemfile
group :test, :development do
  # ..
  gem "rspec-rails"
  gem "sqlite3"
end
```

補強一下 `.gitignore`（記得先 commit）：

```
# .gitignore
/spec/dummy/db/*.sqlite3
/spec/dummy/log/*.log
/spec/dummy/tmp/*
!/spec/dummy/tmp/.keep
```

重新 bundle，來開看看 dummy app：

```
$ bundle install
$ cd spec/dummy
$ rails server
```

喔喔喔噴錯了！

```
uninitialized constant Democi::Engine (NameError)
```

### 自幹 engine

從錯誤訊息來看就是要再自幹 engine：

```
# lib/democi/engine.rb
require "rails/engine"
module Democi
  class Engine < ::Rails::Engine
  end
end
```

一樣也是要把 `engine.rb` 載入主程式：

```
# lib/democi.rb
require "democi/engine"
```

再來啟動一次看看：

```
$ cd spec/dummy
$ rails s
```

成功了！這樣就算是初步設定好 dummy app 了。保險起見，確認一下可以正常動作（到底踩了多少雷）：

```
$ rake spec
```

### 設定 rspec

先做一支 `rails_helper` 給測試程式使用：

```
# spec/rails_helper.rb
require "spec_helper"
require "dummy/config/environment"
require "rspec/rails"
```

馬上來寫測試：

```
# spec/helpers/application_helper_spec.rb
require "rails_helper"
describe ApplicationHelper, type: :helper do
  it { expect(helper.demo).to eq "hello, world!" }
end
```

覺得礙眼的話，就順手把預設的 `democi_spec.rb` 砍掉吧。寫完之後，依開發環境的狀況，`rake spec` 可能會狂噴錯 XD 由於通常都是路徑問題，因此補強一下：

```
# .rspec
--format documentation
--color
--require spec_helper
```

```
# spec/spec_helper.rb
$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "rubygems"
require "bundler/setup"
require "democi"
```

再來跑一次應該就會過了：

```
$ rake spec
```

## Code Climate & Travis CI

先到這邊把你的 github repo 設定起來。Open source 專案可以免費使用。直接以自己的 github 帳號登入最單純：

* [Travis CI](https://travis-ci.org/)
* [Code Climate](https://codeclimate.com/)

加進 test coverage 的 gem 並 bundle：

```
# Gemfile
group :test do
  gem "simplecov"
  gem "codeclimate-test-reporter", "~> 1.0.0"
end
```

加進 test coverage 的設定。這要放在檔案最上面，爬的範圍才會正確：

```
# spec/spec_helper.rb
require "simplecov"
SimpleCov.start do
  add_filter "spec"
end

$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "rubygems"
require "bundler/setup"
require "democi"
```

從 Code Climate 管理介面取得 repo token，加進 Travis CI 的設定檔：

```
# .travis.yml
addons:
  code_climate:
     repo_token: {token}
     
after_success:
  - bundle exec codeclimate-test-reporter
```

改好推上去，就可以在 Code Climate 和 Travis CI 的管理介面看到結果了：

```
$ git push
```

沒有另外設定的話，Travis CI 是預設用 `rake spec` 跑測試的。實務上大家都知道這個常常會杯具，所以通常是會再調教的：

```
# .travis.yml
script:
  - bundle exec rake -f spec/dummy/Rakefile db:migrate
  - bundle exec rspec spec --format documentation
```

## rubygems

這部分網路上資料很多，就隨便講一下就好（喂）

先到 [RubyGems.org](https://rubygems.org/) 註冊帳號。其實打包 gem 的第一步是要先想一個響亮又沒有人用的名字 XD 確定沒有人用的話，就是把打包完的 gem 推上去：

```
$ gem build democi
$ gem push democi-0.1.0.gem
```

推上去之後，其他人就可以用 `gem install democi` 安裝了！
