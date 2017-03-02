require 'spec_helper'

describe PythonLicenseDetector do
  detector = PythonLicenseDetector.new(150, 0.9)

  let(:wtf_text){
    %q[
        DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
                       Version 2, December 2004

    Copyright (C) 2004 Sam Hocevar <sam@hocevar.net>

    Everyone is permitted to copy and distribute verbatim or modified
    copies of this license document, and changing it is allowed as long
    as the name is changed.

               DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
      TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION

     0. You just DO WHAT THE FUCK YOU WANT TO.
     
    ]
  }

  let(:aws_short){
    %q[
      Licensed under the Apache License, Version 2.0 (the "License");
      you may not use this file except in compliance with the License.
      You may obtain a copy of the License at

          http://www.apache.org/licenses/LICENSE-2.0

      Unless required by applicable law or agreed to in writing, software
      distributed under the License is distributed on an "AS IS" BASIS,
      WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
      See the License for the specific language governing permissions and
      limitations under the License.
    ]
  }

  let(:unlicense_txt){ File.read('spec/fixtures/files/licenses/UNLICENSE.txt') }
  let(:mit_txt){ File.read('spec/fixtures/files/licenses/mit.txt') }

  describe "detecting standard spdx license texts" do
    it "detects MIT license by license text" do
      expect(mit_txt.size).to be > 150

      spdx_id, score = detector.detect(mit_txt)
      expect(spdx_id).to eq('mit')
      expect(score).to be > 0.9
    end

    it "detects MIT with rule" do
     spdx_id, score = detector.detect('RELEASED UNDER MIT LICENSE')
     expect(spdx_id).to eq('mit')
     expect(score).to be > 0.99
    end

    it "ignores popular non-sense" do
      spdx_id, score = detector.detect('GNU')
      expect(spdx_id).to eq('GNU')
      expect(score).to eq(-1)
    end
  end

  describe "detects special cases" do
    it "detects WTFPL" do
      spdx_id, score = detector.detect(wtf_text)
      expect(spdx_id).to eq('wtfpl')
      expect(score).to be > 0.9
    end
    
    it "detects APACHE2 short version" do
      spdx_id, score = detector.detect(aws_short)
      expect(spdx_id).to eq('apache2')
      expect(score).to be > 0.9
    end

    it "detects Unlicensed" do
      spdx_id, score = detector.detect(unlicense_txt)
      expect(spdx_id).to eq('unlicense')
      expect(score).to be > 0.9
    end

  end

end

