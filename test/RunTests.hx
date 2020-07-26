package;

import tink.testrunner.*;
import tink.unit.*;

using tink.io.Source;
using bp.test.Utils;

import bp.grpc.GrpcStreamParser;
import bp.grpc.GrpcStreamWriter;

using tink.CoreApi;

class RunTests {
	static function main() {
		Runner.run(TestBatch.make([new BasicTest()])).handle(Runner.exit);
	}
}

@:asserts
class BasicTest {
	public function new() {}

	var parser:GrpcStreamParser<{foo:String}>;
	var writer:GrpcStreamWriter<{foo:String}>;
	var result:Promise<Pair<{foo:String}, RealSource>>;

	@:setup
	public function setup() {
		this.parser = new GrpcStreamParser<{foo:String}>();
		this.writer = new GrpcStreamWriter<{foo:String}>();
		return Noise;
	}

	public function make_stream() {
		var trial = ({
			
			var stream:RealSource = this.writer.getStream();
			this.result = stream.parse(parser).tryRecover(e -> {
				trace(e);
				e;
			});
			this.writer.write({foo: "bar"});
			this.writer.write({foo: "baz"});
			haxe.Timer.delay(() -> {
				this.writer.write({foo: 'qux'});
				this.writer.end();
			}, 2500);
			Noise;
		}).attempt(true);
		return asserts.assert(trial);
	}

	public function consume_stream() {
		this.result.next(t -> {
			asserts.assert(t.a.foo == "bar");
			t.b.parse(parser).next(t -> {
				asserts.assert(t.a.foo == 'baz');
				t.b.parse(parser).next(t -> {
					asserts.assert(t.a.foo == 'qux');
					t.b.parse(parser).next(t -> {
						asserts.assert(t.a == null);
						asserts.done();
					});
				});
			});
		}).tryRecover(e -> {
			trace(e);
			asserts.done();
		}).eager();
		return asserts;
	}
}
