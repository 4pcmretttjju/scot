package Scot::Util::RecordedFuture;

use lib '../../../lib';
use lib '../lib';
use strict;
use warnings;

use Data::Dumper;
use Scot::Env;
use Mojo::UserAgent;
use namespace::autoclean;

use Moose;
extends 'Scot::Util';

has username    => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    lazy        => 1,
    builder     => '_build_username',
    # default     => ' ',
);

sub _build_username {
    my $self    = shift;
    my $attr    = "username";
    my $default = " ";
    my $envname = "scot_util_recfuture_username";
    return $self->get_config_value($attr, $default, $envname);
}

has password    => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    lazy        => 1,
    builder     => '_build_password',
);
sub _build_password {
    my $self    = shift;
    my $attr    = "password";
    my $default = " ";
    my $envname = "scot_util_recfuture_password";
    return $self->get_config_value($attr, $default, $envname);
}

has servername  => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    lazy        => 1,
    builder     => "_build_servername",
    # default     => 'www.recfuture.com/vtapi',
    # default     => 'vproxy',
);
sub _build_servername {
    my $self    = shift;
    my $attr    = "servername";
    my $default = "www.recfuture.com/vtapi";
    my $envname = "scot_util_recfuture_servername";
    return $self->get_config_value($attr, $default, $envname);
}

has ua          => (
    is          => 'ro',
    isa         => 'Mojo::UserAgent',
    required    => 1,
    lazy        => 1,
    clearer     => 'clear_ua',
    builder     => '_build_useragent',
);

has api_key     => (
    is          => 'rw',
    isa         => 'Str',
    required    => 1,
    lazy        => 1,
    builder     => "_build_api_key",
);

sub _build_api_key {
    my $self    = shift;
    my $attr    = "api_key";
    my $default = " ";
    my $envname = "scot_util_recfuture_api_key";
    return $self->get_config_value($attr, $default, $envname);
}




sub _build_useragent {
    my $self    = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $ua      = Mojo::UserAgent->new();
    my $url     = sprintf "https://%s:%s@%s/auth/request-token",
                    $self->username,
                    $self->password,
                    $self->servername;
    my $tx      = $ua->get($url);

    if ( my $res    = $tx->success ) {
        $log->debug($self->username." authenticated to ".$self->servername);
        #$log->debug({filter=>\&Dumper, value => $tx});
        my $resp    = $tx->res;
        my $json    = $resp->json;
        $log->debug("JSON is: ",{filter=>\&Dumper, value => $json});
        my $apikey  = $json->{apikey};
        $self->api_key($apikey);
    }
    else {
        $log->error($self->username." failed to authenticate to ".$self->servername);
        $log->error({filter => \&Dumper, value => $tx});
    }
    return $ua;
}

sub do_request {
    my $self    = shift;
    my $verb    = shift;
    my $url     = shift;
    my $params  = shift;    # urlencodedvars=value&foo=bar  
    my $env     = $self->env;
    my $log     = $env->log;
    my $ua      = $self->ua;
    my $prefix  = "https://".$self->servername;


    $log->debug("[api_key] ".$self->api_key);
    $log->debug("[url]     ".$url);
    $log->debug("[params]  ".$params);

    $url    = $prefix . $url . "?apikey=".$self->api_key;
    $url    .= "&".$params if $params;

    $log->trace("[MojoUA] $verb $url");

    my $tx  = $ua->$verb($url);
    if ( my $res    = $tx->success ) {
        $log->debug("$verb successful");
        return $tx;
    }
    $log->error("$verb failed! ",{ filter =>\&Dumper, value => $tx->error});
    return undef;
}

## a sample get function
## params in this case would be the param string, e.g ?foo=bar&boom=baz
## necessary to retrieve the data

sub get_XXX {
    my $self    = shift;
    my $params  = shift;
    my $env     = $self->env;
    my $log     = $env->log;
    my $url     = "/v2/XXX";

    $log->trace("Getting XXX with $params");

    if ( my $tx  = $self->do_request("get", $url, $params) ) {
        return $tx->res->json;
    }
    else {
        $log->error("Failed to get comments!");
    }
    return undef;
}

## we can create similar functions to post/put/delete
## essentially you will call do_request("post",...) or "put", etc.

## writing into SCOT
## if a mongo entry is in the config, this class will have access
## to the $mongo reference that we can use to write data to the DB.

## Sample fetch of data to a mythical RecFuture api, and writing the
## result to the entity's record

sub enrich_entity {
    my $self	= shift;
    my $entity  = shift;    # obj reference to entity 
                            # entity objects have a value and type
    my $query   = "value=".$entity->value."&"."type=".$entity->type;
    $query .= "&other_params_necessary_for_get";
    my $json    = $self->get_XXX($query);

    # example one: push the returned JSON into entity.data record
    # entity objects have an update method, that updates the db
    # and syncs the object with the new data
    # this could be exposed to the user, via the entity popup as 
    # a tab like the geoip tab
    $entity->update({
        '$set'  => {
            data    => {
                recorded_future => $json # or HTML string if you like
            }
        }
    });

    # example two: create an html entry of the returned data
    # create_html is an exercise left for later, unless your
    # api can return HTML as well.  Alternatively, the 
    # do_request headers can be modified to request HTML
    # this would be visible to the user in the entry list at the bottom
    # of the entity popup
    my $html    = $self->create_html($json);

    my $entry_collection    = $self->env->mongo->collection('Entry');
    # see SCOT/lib/Scot/Model/Entry.pm for list of all possible fields
    my $entry   = $entry_collection->create({
        target      => {
            id   => $entity->id,
            type => "entity",
        },
        body        => $html,
        class       => "entry",
        tlp         => "green",
    });
    # notify flair engine that an entry is available for flair-ing
    $self->env->mq->send("/topic/scot", {
        action  => "created",
        data    => {
            who     => "recfuture_enricher",
            type    => "entry",
            id      => $entry->id,
            target  => {
                id  => $entity->id,
                type    => "entity",
            }
        },
    });
}



__PACKAGE__->meta->make_immutable;
1;
