# Copyright © 2017 Broadcom
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

libkmsrowinsys = static_library(
  'kmsrowinsys',
  files('kmsro_drm_winsys.c'),
  include_directories : [
    inc_src, inc_include, inc_loader,
    inc_gallium, inc_gallium_aux, inc_gallium_winsys,
  ],
  link_with : libloader,
  c_args : [renderonly_drivers_c_args],
  gnu_symbol_visibility : 'hidden',
  dependencies: [dep_libdrm, idep_mesautil],
)

driver_kmsro = declare_dependency(
  compile_args : '-DGALLIUM_KMSRO',
  link_with : libkmsrowinsys,
)
