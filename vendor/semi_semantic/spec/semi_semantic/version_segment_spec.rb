require 'spec_helper'
require 'semi_semantic/version_segment'

module SemiSemantic
  describe VersionSegment do

    describe 'parse' do
      it 'handles one or more non-negative numerical components' do
        expect(described_class.parse('1').components).to eq [1]
        expect(described_class.parse('1.1').components).to eq [1,1]
        expect(described_class.parse('1.1.1').components).to eq [1,1,1]
        expect(described_class.parse('1.1.1.1').components).to eq [1,1,1,1]

        expect(described_class.parse('123.0.1').components).to eq [123,0,1]
      end

      it 'handles negative numerical components as strings' do
        expect(described_class.parse('-1').components).to eq ['-1']
        expect(described_class.parse('0.-1').components).to eq [0, '-1']
      end

      it 'handles alphanumerics, hyphens & underscores in components as strings' do
        expect(described_class.parse('a').components).to eq ['a']
        expect(described_class.parse('a.b.c').components).to eq ['a', 'b', 'c']
        expect(described_class.parse('1-1').components).to eq ['1-1']
        expect(described_class.parse('alpha-12.5.-').components).to eq ['alpha-12', 5, '-']
        expect(described_class.parse('1.2.3.alpha').components).to eq [1, 2, 3, 'alpha']
        expect(described_class.parse('2013-03-21_01-53-17').components).to eq ['2013-03-21_01-53-17']
      end

      it 'raises an ArgumentError for the empty string' do
        expect { described_class.parse('') }.to raise_error(ArgumentError)
      end

      it 'raises an ParseError for non-alphanumeric, non-hyphen, non-underscore characters' do
        expect { described_class.parse('+') }.to raise_error(ParseError)
        expect { described_class.parse('&') }.to raise_error(ParseError)
        expect { described_class.parse(' ') }.to raise_error(ParseError)
        expect { described_class.parse("\u{6666}") }.to raise_error(ParseError)
        expect { described_class.parse("1.\u{6666}") }.to raise_error(ParseError)
      end
    end

    describe 'new' do
      it 'saves the supplied components' do
        components = [1, 2, 3]
        expect(described_class.new(components).components).to eq components
      end

      it 'raises an ArgumentError for an empty array' do
        expect { described_class.new([]) }.to raise_error(ArgumentError)
      end

      it 'raises an ArgumentError for the empty string' do
        expect { described_class.new(['']) }.to raise_error(ArgumentError)
        expect { described_class.new([0, '']) }.to raise_error(ArgumentError)
      end

      it 'raises an ArgumentError for non-string & non-integer components' do
        expect { described_class.new([1.1]) }.to raise_error(ArgumentError)
        expect { described_class.new([true]) }.to raise_error(ArgumentError)
        expect { described_class.new([[]]) }.to raise_error(ArgumentError)
      end
    end

    describe 'to string' do
      it 'joins the version clusters with separators' do
        expect(described_class.new([1]).to_s).to eq '1'
        expect(described_class.new([1, 1, 1, 1]).to_s).to eq '1.1.1.1'
        expect(described_class.new([1, 'a', 1, 1]).to_s).to eq '1.a.1.1'
        expect(described_class.new([1, 'a', 1, '-1']).to_s).to eq '1.a.1.-1'
      end
    end

    describe 'increment' do
      it 'increases the least significant component by default' do
        expect(described_class.new([1]).increment.components).to eq [2]
        expect(described_class.new([1, 1, 1, 1]).increment.components).to eq [1, 1, 1, 2]
        expect(described_class.new([1, 'a', 0, 0]).increment.components).to eq [1, 'a', 0, 1]
      end

      it 'raises a TypeError if the specified index is not an integer' do
        expect { described_class.new(['a']).increment }.to raise_error(TypeError)
        expect { described_class.new([1, 1, 1, 'a']).increment }.to raise_error(TypeError)
        expect { described_class.new([0, '-1']).increment }.to raise_error(TypeError)
      end

      it 'resets to 0 all numeric components after the given index' do
        expect(described_class.new([1, 1, 1]).increment(0).components).to eq [2, 0, 0]
        expect(described_class.new([1, 1, 1, 'alpha', 5]).increment(0).components).to eq [2, 0, 0, 'alpha', 0]
        expect(described_class.new([1, 1, 1]).increment(1).components).to eq [1, 2, 0]
        expect(described_class.new([1, 1, 1]).increment(-1).components).to eq [1, 1, 2]
        expect(described_class.new([1, 1, 1]).increment(-2).components).to eq [1, 2, 0]
      end
    end

    describe 'decrement' do
      it 'decreases the least significant component by default' do
        expect(described_class.new([1]).decrement.components).to eq [0]
        expect(described_class.new([1, 1, 1, 1]).decrement.components).to eq [1, 1, 1, 0]
        expect(described_class.new([1, 'a', 0, 1]).decrement.components).to eq [1, 'a', 0, 0]
      end

      it 'raises a TypeError if the specified index is not an integer' do
        expect { described_class.new(['a']).decrement }.to raise_error(TypeError)
        expect { described_class.new([1, 1, 1, 'a']).decrement }.to raise_error(TypeError)
        expect { described_class.new([0, '-1']).decrement }.to raise_error(TypeError)
      end

      it 'raises a RangeError if the specified index is zero or less' do
        expect { described_class.new([0]).decrement }.to raise_error(RangeError)
        expect { described_class.new([1, 1, 1, 'a', 0]).decrement }.to raise_error(RangeError)
        expect { described_class.new([0, '-1', 0]).decrement }.to raise_error(RangeError)
        expect { described_class.new([-1]).decrement }.to raise_error(RangeError)
      end
    end

    describe 'compare' do

      it 'does not raise an error when comparing against nil' do
        expect { described_class.parse('1.0.1') == nil }.to_not raise_exception
      end

      it 'assumes appended zeros' do
        expect(described_class.new([0])).to eq described_class.new([0, 0])
        expect(described_class.new([1, 0])).to eq described_class.new([1, 0, 0, 0])
        expect(described_class.new([1, 2, 3])).to eq described_class.new([1, 2, 3, 0])
        expect(described_class.new(['a'])).to eq described_class.new(['a', 0])

        expect(described_class.new([1, 0])).to be > described_class.new([0])
        expect(described_class.new([1, 1, 1])).to be > described_class.new([1, 1])

        expect(described_class.new([0])).to be < described_class.new([1, 0])
        expect(described_class.new([1, 1])).to be < described_class.new([1, 1, 1])
      end

      it 'compares integers numerically' do
        expect(described_class.new([1])).to eq described_class.new([1])

        expect(described_class.new([2])).to be > described_class.new([1])
        expect(described_class.new([1])).to be > described_class.new([0])
        expect(described_class.new([1, 2, 4])).to be > described_class.new([1, 2, 3])
      end

      it 'compares strings alpha-numerically' do
        expect(described_class.new(['a'])).to eq described_class.new(['a'])

        expect(described_class.new(['beta', 1])).to be > described_class.new(['alpha', 1])
        expect(described_class.new(['123abc'])).to be > described_class.new(['123ab'])

        expect(described_class.new(['a'])).to be < described_class.new(['a', 1])
        expect(described_class.new(['123ab'])).to be < described_class.new(['123abc'])

        expect(described_class.new(['2013-03-21_01-53-17'])).to be < described_class.new(['2013-03-21_12-00-00'])
      end

      it 'values numbers lower than non-numbers' do
        expect(described_class.new([1])).to be < described_class.new(['a'])
        expect(described_class.new([1, 'a'])).to be > described_class.new([1, 0])
      end
    end

  end
end
