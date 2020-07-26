package;

import tink.testrunner.*;
import tink.unit.*;

using tink.io.Source;
using bp.test.Utils;

import bp.grpc.GrpcStreamParser;
import bp.grpc.GrpcStreamWriter;
import tink.streams.*;
import tink.streams.Stream;

using tink.CoreApi;

class RunTests {
	static function main() {
		Runner.run(TestBatch.make([new BasicTest()])).handle(Runner.exit);
	}
}

@:asserts
class BasicTest {
	public function new() {}

	var reader:GrpcReader<Null<{foo:String}>>;
	var writer:GrpcWriter<Null<{foo:String}>>;
	var result:Promise<Pair<Null<{foo:String}>, RealSource>>;

	@:setup
	public function setup() {
		this.reader = new GrpcStreamParser<Null<{foo:String}>>();
		this.writer = new GrpcStreamWriter<Null<{foo:String}>>();
		return Noise;
	}

	public function make_stream() {
		var trial = ({
			var stream:RealSource = this.writer;
			this.result = stream.parse(reader).tryRecover(e -> {
				trace(e);
				e;
			});
			this.writer.write({foo: "bar"});
			this.writer.write({foo: "baz"});
			haxe.Timer.delay(() -> {
				this.writer.write({foo: 'qux'});
				haxe.Timer.delay(() -> {
					this.writer.write(null);
					haxe.Timer.delay(() -> {
						this.writer.end();
					}, 500);
				}, 1000);
			}, 2500);
			Noise;
		}).attempt(true);
		return asserts.assert(trial);
	}

	@:timeout(10000)
	public function parse_reader() {
		this.result.next(t -> {
			asserts.assert(t.a.foo == "bar");
			t.b.parse(reader).next(t -> {
				asserts.assert(t.a.foo == 'baz');
				t.b.parse(reader).next(t -> {
					asserts.assert(t.a.foo == 'qux');
					t.b.parse(reader).next(t -> {
						asserts.assert(t.a == null);
						asserts.assert(!t.b.depleted);
						t.b.parse(reader).next(t -> {
							asserts.assert(t.b.depleted);
							asserts.done();
						});
					});
				});
			});
		}).tryRecover(e -> {
			trace(e);
			asserts.done();
		}).eager();
		return asserts;
	}

	public function streaming() {
		var source:RealSource = this.writer;
		this.reader.prepare(source);
		var stream:RealStream<Null<{foo:String}>> = this.reader;
		var i = 0;
		var i2 = 0;
		stream.forEach(c -> {
			if (c != null) {
				asserts.assert(c.foo == '${i2++}');
				Resume;
			} else
				BackOff;
		}).handle(_ -> {
			asserts.done();
		});
		for (i in 0...10) {
			this.writer.write({foo: '$i'});
		}
		this.writer.end();
		return asserts;
	}
}
