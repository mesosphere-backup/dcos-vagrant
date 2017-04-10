require 'spec_helper'
require 'semi_semantic/version'

module SemiSemantic
  describe Version do

    describe 'release' do
      it 'returns the first VersionCluster' do
        expect(described_class.parse('1.0').release).to eq VersionSegment.parse '1.0'
        expect(described_class.parse('1.0-alpha').release).to eq VersionSegment.parse '1.0'
        expect(described_class.parse('1.0+dev').release).to eq VersionSegment.parse '1.0'
        expect(described_class.parse('1.0-alpha+dev').release).to eq VersionSegment.parse '1.0'
      end
    end

    describe 'pre_release' do
      it 'returns the VersionCluster following the "-"' do
        expect(described_class.parse('1.0').pre_release).to be_nil
        expect(described_class.parse('1.0-alpha').pre_release).to eq VersionSegment.parse 'alpha'
        expect(described_class.parse('1.0+dev').pre_release).to be_nil
        expect(described_class.parse('1.0-alpha+dev').pre_release).to eq VersionSegment.parse 'alpha'
      end
    end

    describe 'post_release' do
      it 'returns the VersionCluster following the "+"' do
        expect(described_class.parse('1.0').post_release).to be_nil
        expect(described_class.parse('1.0-alpha').post_release).to be_nil
        expect(described_class.parse('1.0+dev').post_release).to eq VersionSegment.parse 'dev'
        expect(described_class.parse('1.0-alpha+dev').post_release).to eq VersionSegment.parse 'dev'
      end
    end

    describe 'parse' do
      it 'parses up to 3 segments' do
        segment_a = VersionSegment.parse '1.0.a'
        segment_b = VersionSegment.parse '1.0.b'
        segment_c = VersionSegment.parse '1.0.c'
        expect(described_class.parse('1.0.a-1.0.b+1.0.c').segments).to eq [segment_a, segment_b, segment_c]
        expect(described_class.parse('1.0.a-1.0.b').segments).to eq [segment_a, segment_b]
        expect(described_class.parse('1.0.a+1.0.c').segments).to eq [segment_a, segment_c]
        expect(described_class.parse('1.0.a').segments).to eq [segment_a]
      end

      it 'raises a ParseError if a segment fails to parse' do
        version_segment = class_double('SemiSemantic::VersionSegment').as_stubbed_const
        allow(version_segment).to receive(:parse).and_raise(ParseError)

        expect { described_class.parse('1.0') }.to raise_error(ParseError)
      end

      it 'supports hyphenation in pre/post-release segments' do
        v = described_class.parse('1-1-1')
        expect(v.release).to eq VersionSegment.parse '1'
        expect(v.pre_release).to eq VersionSegment.parse '1-1'
        expect(v.post_release).to be_nil

        v = described_class.parse('1+1-1')
        expect(v.release).to eq VersionSegment.parse '1'
        expect(v.pre_release).to be_nil
        expect(v.post_release).to eq VersionSegment.parse '1-1'

        v = described_class.parse('1-1-1+1-1')
        expect(v.release).to eq VersionSegment.parse '1'
        expect(v.pre_release).to eq VersionSegment.parse '1-1'
        expect(v.post_release).to eq VersionSegment.parse '1-1'
      end

      it 'raises a ParseError for empty segments' do
        expect { described_class.parse('+1') }.to raise_error(ParseError)
        expect { described_class.parse('1+') }.to raise_error(ParseError)
        expect { described_class.parse('-1') }.to raise_error(ParseError)
        expect { described_class.parse('1-') }.to raise_error(ParseError)
        expect { described_class.parse('1-+1') }.to raise_error(ParseError)
        expect { described_class.parse('1-1+') }.to raise_error(ParseError)
      end

      it 'raises a ParseError if multiple post-release segments' do
        expect { described_class.parse('1+1+1') }.to raise_error(ParseError)
      end

      it 'raises an ArgumentError for the empty string' do
        expect { described_class.parse('') }.to raise_error(ArgumentError)
      end

      it 'raises a ParseError for invalid characters' do
        expect { described_class.parse(' ') }.to raise_error(ParseError)
        expect { described_class.parse('1 1') }.to raise_error(ParseError)
        expect { described_class.parse('can\'t do it cap\'n') }.to raise_error(ParseError)
      end
    end

    describe 'to string' do
      it 'joins the version clusters with separators' do
        release = VersionSegment.parse '1.1.1.1'
        pre_release = VersionSegment.parse '2.2.2.2'
        post_release = VersionSegment.parse '3.3.3.3'

        expect(described_class.new(release).to_s).to eq '1.1.1.1'
        expect(described_class.new(release, pre_release).to_s).to eq '1.1.1.1-2.2.2.2'
        expect(described_class.new(release, nil, post_release).to_s).to eq '1.1.1.1+3.3.3.3'
        expect(described_class.new(release, pre_release, post_release).to_s).to eq '1.1.1.1-2.2.2.2+3.3.3.3'
      end
    end

    describe 'compare' do
      it 'handles equivalence' do
        expect(described_class.parse('1.0')).to eq described_class.parse('1.0')
        expect(described_class.parse('1.0')).to eq described_class.parse('1.0.0')
        expect(described_class.parse('1-1+1')).to eq described_class.parse('1-1+1')

        expect(described_class.parse('1-1+0')).to_not eq described_class.parse('1-1')
      end

      it 'treats nil pre/post-release as distinct from zeroed pre/post-release' do
        expect(described_class.parse('1-0+1')).to_not eq described_class.parse('1+1')
        expect(described_class.parse('1-1+0')).to_not eq described_class.parse('1-1')
      end

      it 'treats pre-release as less than release' do
        expect(described_class.parse('1.0-alpha')).to be < described_class.parse('1.0')
      end

      it 'treats post-release as greater than release' do
        expect(described_class.parse('1.0+dev')).to be > described_class.parse('1.0')
      end
    end

  end
end
