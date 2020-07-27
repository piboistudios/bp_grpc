package;

import tink.http.containers.*;
import tink.http.Response;
import tink.web.routing.*;
import tink.http.clients.*;
import tink.web.proxy.Remote;
import tink.url.Host;
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
		Runner.run(TestBatch.make([new BasicTest(), new WebTest()])).handle(Runner.exit);
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

class Grpc {
	public function new() {}

	@:get('/')
	public function echo(body:RealSource):RealSource {
		var reader = new GrpcStreamParser<{msg:String}>(body).toStream();
		var source = body;
		var writer:GrpcWriter<{msg:String}> = new GrpcStreamWriter<{msg:String}>();
		reader.forEach(m -> {
			if (m != null) {
				writer.write({msg: 'echo: ${m.msg}'});
			}
			Resume;
		}).handle(_ -> {
			writer.end();
		});
		return writer;
	}
}

@:asserts
class WebTest {
	var container:LocalContainer;
	var remote:Remote<Grpc>;

	public function new() {}

	@:setup
	public function setup() {
		this.container = new LocalContainer();
		var router = new Router<Grpc>(new Grpc());
		container.run(req -> {
			return router.route(Context.ofRequest(req)).recover(OutgoingResponse.reportError);
		});
		var client = new LocalContainerClient(this.container);
		this.remote = new Remote<Grpc>(client, new RemoteEndpoint(new Host('localhost', 80)));
		return Noise;
	}

	public function test_echo() {
		var writer:GrpcWriter<{msg:String}> = new GrpcStreamWriter<{msg:String}>();
		remote.echo(writer).next(res -> {
			var reader:GrpcReader<{msg:String}> = new GrpcStreamParser<{msg:String}>(res.body);
			var stream:RealStream<{msg:String}> = reader;
			var i = 0;
			stream.forEach(m -> {
				if(m != null) asserts.assert(m.msg == 'echo: ${i++}');
				Resume;
			}).handle(_ -> {
				asserts.done();
			});
		}).eager();
		for (i in 0...10)
			writer.write({msg: '$i'});
		writer.end();
		return asserts;
	}
}
