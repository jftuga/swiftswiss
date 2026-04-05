// This C shim exists because res_query and dn_expand are #define macros on
// macOS (they redirect to res_9_query and res_9_dn_expand respectively), and
// Swift cannot import C preprocessor macros.
//
// To eliminate this file and make the project 100% Swift source, you could
// replace these wrappers with @_silgen_name declarations in Swift:
//
//   @_silgen_name("res_9_query")
//   private func res_query(_ dname: UnsafePointer<CChar>, _ cls: Int32,
//       _ type: Int32, _ answer: UnsafeMutablePointer<UInt8>,
//       _ anslen: Int32) -> Int32
//
//   @_silgen_name("res_9_dn_expand")
//   private func dn_expand(_ msg: UnsafePointer<UInt8>,
//       _ eom: UnsafePointer<UInt8>, _ src: UnsafePointer<UInt8>,
//       _ dst: UnsafeMutablePointer<CChar>, _ dstsiz: Int32) -> Int32
//
// The tradeoff: @_silgen_name is an underscored/unofficial Swift attribute, so
// it is not guaranteed to be stable across Swift versions. In practice it has
// been stable for years and is widely used for exactly this kind of system
// interop. The C shim approach used here is the safer, more conventional choice.

#include <resolv.h>
#include "CResolv.h"

int cresolv_query(const char *dname, int class_field, int type,
                  unsigned char *answer, int anslen) {
    return res_query(dname, class_field, type, answer, anslen);
}

int cresolv_dn_expand(const unsigned char *msg, const unsigned char *eom,
                      const unsigned char *src, char *dst, int dstsiz) {
    return dn_expand(msg, eom, src, dst, dstsiz);
}
