package bp.grpc;


import tink.CoreApi;
import tink.io.Source;


@:genericBuild(bp.grpc.Macros.GrpcStreamParserBuilder.buildWriter())
class GrpcStreamWriter<T> {
    public function new() {
        throw 'not implemented';
    }
    public function write(object:T) {
        throw 'not implemented';
    }
    public function end() {
        throw 'not implemented';
    }

    public function error(e) {
        throw 'not implemented';
    }

    public function getStream():IdealSource
        throw 'not implemented';
    
}