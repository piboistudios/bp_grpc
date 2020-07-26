package bp.grpc;

import tink.CoreApi;
import tink.io.Source;
@:forward
abstract GrpcWriter<T>(GrpcStreamWriterBase<T>) from GrpcStreamWriterBase<T> to GrpcStreamWriterBase<T> {
	@:to public function toSource():RealSource
		return this.toSource();
}

class GrpcStreamWriterBase<T> {
	var signal:tink.core.Signal.SignalTrigger<tink.streams.Stream.Yield<tink.Chunk, tink.core.Error>>;
    public function write(write:T) {
        throw 'not implemented';
    }
	public function end() {
		signal.trigger(End);
	}

	public function error(e) {
		signal.trigger(Fail(e));
	}

	public function toSource():tink.io.Source.RealSource {
		return new tink.streams.Stream.SignalStream(this.signal);
	}
}

@:genericBuild(bp.grpc.Macros.GrpcStreamParserBuilder.buildWriter())
class GrpcStreamWriter<T> {
	public function new() {
		throw 'not implemented';
	}

	public function write(object:T) {
		throw 'not implemented';
	}
}
