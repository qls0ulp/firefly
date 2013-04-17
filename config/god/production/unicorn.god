# vim: ft=ruby

Ifad::God.unicorn do |w|
  w.uid = 'firefly'
  w.gid = 'ruby'
  w.env = {
    'RACK_ENV'               => 'production',
    'RACK_RELATIVE_URL_ROOT' => '/'
  }
end
