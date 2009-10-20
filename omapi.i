/* Python Omapi Interface */
%module omapi
%feature("autodoc", "1");
%{
#include <dhcpctl.h>
#include <netinet/ether.h>
#include <netinet/in.h>

typedef struct {
        dhcpctl_handle conn;
} Omapi;

void dhcpctl_error(char *p, dhcpctl_status status) { 
        printf("%s: %s\n",p,isc_result_totext(status)); 
}

static dhcpctl_handle dhcpd_connect_with_auth( const char *hostname, int port,
                        const char* username, const unsigned char *key)
{
        dhcpctl_handle auth = NULL;
        unsigned char *keydata = NULL;
        int keylen = 0;
        dhcpctl_status status;
        dhcpctl_handle conn = NULL;

        /* Set authentication */
        base64_decode(key,&keydata,&keylen);

        if ((status = dhcpctl_new_authenticator(&auth, username, "hmac-md5",
                                        keydata, keylen)))
                dhcpctl_error("Can't load authentication information",status);

        /* Connect */
        if ((status = dhcpctl_connect (&conn, hostname, port, auth)))
                dhcpctl_error ("Can't connect to dhcp server with auth",
                                status);
        return conn;
}

/* Connect to (and authenticate with) the dhcp server */
dhcpctl_handle dhcpd_connect( char *hostname, int port, char* username,  unsigned char *key) {
        dhcpctl_status status;
        dhcpctl_handle conn = NULL;
        status = dhcpctl_initialize();
        omapi_init();

        if (key) {
                conn = dhcpd_connect_with_auth(hostname,port,username,key);
        } else {
                if ((status = dhcpctl_connect (&conn, hostname, port, dhcpctl_null_handle))) {
                        dhcpctl_error("failed to connect",status);
                        return NULL;
                }
        }
        return conn;
}


%}

typedef struct {
} Omapi;

%extend Omapi {
        Omapi( char *hostname, int port,  char *username, char *key) {
                Omapi *o;
                o=(Omapi *)malloc(sizeof(Omapi));
                o->conn=dhcpd_connect(hostname,port,username,key);
                return o;
        }

        ~Omapi() {
                /* Shouldn't we free o->conn or something? */
                free(self);
        }

void add_host( char *ip,  char *mac) {
        dhcpctl_status status;
        dhcpctl_status status2;
        dhcpctl_handle hp = NULL;
        dhcpctl_data_string ds = NULL;
        omapi_data_string_t *nds;

        if ((status = dhcpctl_new_object(&hp, self->conn, "host"))) dhcpctl_error("host create failed", status);

        if (!ether_aton(mac)) {
                printf("oi! Thats not a mac!\n");
                return;
        }

        omapi_data_string_new(&ds, sizeof(struct ether_addr), __FILE__, __LINE__);
        memcpy(ds->value,ether_aton(mac),sizeof(struct ether_addr));
        if ((status = dhcpctl_set_value(hp, ds, "hardware-address"))) dhcpctl_error("Failed to set hardware-address",status);

        if (ip) {
                omapi_data_string_new(&ds, sizeof(struct in_addr), __FILE__, __LINE__);
                inet_aton(ip,(struct in_addr*)&ds->value);
                if ((status = dhcpctl_set_value(hp, ds, "ip-address"))) dhcpctl_error("Failed to set ip-address",status);
               
                nds = (omapi_data_string_t *)0;
                omapi_data_string_new(&nds, strlen(ip), MDL);
                memcpy(nds->value,ip,strlen(ip));
                if ((status = dhcpctl_set_value(hp, nds, "name"))) dhcpctl_error("Failed to set name",status);
        }

        if ((status= dhcpctl_set_int_value(hp, 1,"hardware-type"))) dhcpctl_error("Failed to set hardware-type",status);
        if ((status = dhcpctl_open_object(hp, self->conn, DHCPCTL_CREATE|DHCPCTL_EXCL))) dhcpctl_error("Failed to create",status);
        if ((status = dhcpctl_wait_for_completion(hp, &status2))) dhcpctl_error("Completion failed",status);
        if (status2) {
                dhcpctl_error("add",status2);
                omapi_object_dereference(&hp,__FILE__,__LINE__);
                return;
        }

        omapi_object_dereference(&hp,__FILE__,__LINE__);

        return ;
}

void del_host( char *mac, char *hostname ) {
        dhcpctl_status status;
        dhcpctl_status status2;
        dhcpctl_handle hp = NULL;
        dhcpctl_data_string ds = NULL;
        omapi_data_string_t *nds;
        char *ret;

        if ((status = dhcpctl_new_object(&hp, self->conn, "host"))) dhcpctl_error("host create failed", status);

        if (mac) {
                omapi_data_string_new(&ds, sizeof(struct ether_addr), __FILE__, __LINE__);
                memcpy(ds->value,ether_aton(mac),sizeof(struct ether_addr));
                if ((status = dhcpctl_set_value(hp, ds, "hardware-address"))) dhcpctl_error("Failed to set hardware-address",status);
                if ((status = dhcpctl_set_int_value(hp, 1, "hardware-type"))) dhcpctl_error("Failed to set hardware-type",status);
        }
        
        if (hostname) {
                nds = (omapi_data_string_t *)0;
                omapi_data_string_new(&nds, strlen(hostname), MDL);
                memcpy(nds->value,hostname,strlen(hostname));
                if ((status = dhcpctl_set_value(hp, nds, "name"))) dhcpctl_error("Failed to set name",status);
        }

        if ((status = dhcpctl_open_object(hp, self->conn, 0))) dhcpctl_error("Failed to refresh query (open)",status);
        if ((status = dhcpctl_wait_for_completion(hp, &status2))) dhcpctl_error("Completion failed (open)",status);
        if (status2) dhcpctl_error("delete (open)",status2);
        if ((status = dhcpctl_object_remove(self->conn, hp))) dhcpctl_error("Failed to refresh query",status);
        if ((status = dhcpctl_wait_for_completion(hp, &status2))) dhcpctl_error("Completion failed",status);
        if (status2) dhcpctl_error("delete",status2);
        omapi_object_dereference(&hp,__FILE__,__LINE__);
        return ret;
}


char *lookup_lease_ip( char *mac) {
        dhcpctl_status status;
        dhcpctl_status status2;
        dhcpctl_handle hp = NULL;
        dhcpctl_data_string result = NULL;
        dhcpctl_data_string ds = NULL;
        struct in_addr addr;
        char *ret;

        if ((status = dhcpctl_new_object(&hp, self->conn, "lease"))) dhcpctl_error("lease create failed", status);

        omapi_data_string_new(&ds, sizeof(struct ether_addr), __FILE__, __LINE__);
        memcpy(ds->value,ether_aton(mac),sizeof(struct ether_addr));

        if ((status = dhcpctl_set_value(hp, ds, "hardware-address"))) dhcpctl_error("Failed to set hardware-address",status);

        if ((status = dhcpctl_open_object(hp, self->conn, 0))) dhcpctl_error("Failed to refresh query",status);

        if ((status = dhcpctl_wait_for_completion(hp, &status2))) dhcpctl_error("Completion failed",status);
        if (status2) {
                omapi_object_dereference(&hp,__FILE__,__LINE__);
                return NULL;
        }

        if ((status = dhcpctl_get_value(&result, hp, "ip-address"))) {
                omapi_object_dereference(&hp,__FILE__,__LINE__);
                return NULL;
        }

        memcpy(&addr,result->value,sizeof(addr));
        ret=inet_ntoa(*(struct in_addr*)&addr);

        omapi_object_dereference(&hp,__FILE__,__LINE__);
        return ret;
}


char *lookup_host_ip( char *mac) {
        dhcpctl_status status;
        dhcpctl_status status2;
        dhcpctl_handle hp = NULL;
        dhcpctl_data_string result = NULL;
        dhcpctl_data_string ds = NULL;
        struct in_addr addr;
        char *ret;

        if ((status = dhcpctl_new_object(&hp, self->conn, "host"))) dhcpctl_error("host create failed", status);

        omapi_data_string_new(&ds, sizeof(struct ether_addr), __FILE__, __LINE__);
        memcpy(ds->value,ether_aton(mac),sizeof(struct ether_addr));

        if ((status = dhcpctl_set_value(hp, ds, "hardware-address"))) dhcpctl_error("Failed to set hardware-address",status);

        if ((status = dhcpctl_open_object(hp, self->conn, 0))) dhcpctl_error("Failed to refresh query",status);

        if ((status = dhcpctl_wait_for_completion(hp, &status2))) dhcpctl_error("Completion failed",status);
        if (status2) {
                omapi_object_dereference(&hp,__FILE__,__LINE__);
                return NULL;
        }

        if ((status = dhcpctl_get_value(&result, hp, "ip-address"))) {
                omapi_object_dereference(&hp,__FILE__,__LINE__);
                return NULL;
        }

        memcpy(&addr,result->value,sizeof(addr));
        ret=inet_ntoa(*(struct in_addr*)&addr);

        omapi_object_dereference(&hp,__FILE__,__LINE__);

        return ret;
}

char *lookup_lease_mac( char *ip) {
        dhcpctl_status status;
        dhcpctl_status status2;
        dhcpctl_handle hp = NULL;
        dhcpctl_data_string result = NULL;
        dhcpctl_data_string ds = NULL;
        char *ret;

        if ((status = dhcpctl_new_object(&hp, self->conn, "lease"))) dhcpctl_error("lease create failed", status);

        omapi_data_string_new(&ds, sizeof(struct in_addr), __FILE__, __LINE__);
        inet_aton(ip,(struct in_addr*)&ds->value);

        if ((status = dhcpctl_set_value(hp, ds, "ip-address"))) dhcpctl_error("Failed to set ip-address",status);

        if ((status = dhcpctl_open_object(hp, self->conn, 0))) dhcpctl_error("Failed to refresh query",status);

        if ((status = dhcpctl_wait_for_completion(hp, &status2))) dhcpctl_error("Completion failed",status);
  
        if (status2) {
                omapi_object_dereference(&hp,__FILE__,__LINE__);
                return NULL;
        }

        if ((status = dhcpctl_get_value(&result, hp, "hardware-address"))) {
                omapi_object_dereference(&hp,__FILE__,__LINE__);
                return NULL;
        }

        ret=ether_ntoa((struct ether_addr*)&result->value);

        omapi_object_dereference(&hp,__FILE__,__LINE__);

        return ret;
}
        
char *lookup_host_mac( char *hostname) {
        dhcpctl_status status;
        dhcpctl_status status2;
        dhcpctl_handle hp = NULL;
        dhcpctl_data_string result = NULL;
        omapi_data_string_t *nds;
        char *ret;

        if ((status = dhcpctl_new_object(&hp, self->conn, "host"))) dhcpctl_error("host create failed", status);

        nds = (omapi_data_string_t *)0; 
        status = omapi_data_string_new(&nds, strlen(hostname), MDL);
        memcpy(nds->value,hostname,strlen(hostname));
  
        if ((status = dhcpctl_set_value(hp, nds, "name"))) dhcpctl_error("Failed to set hostname",status);

        if ((status = dhcpctl_open_object(hp, self->conn, 0))) dhcpctl_error("Failed to refresh query",status);

        if ((status = dhcpctl_wait_for_completion(hp, &status2))) dhcpctl_error("Completion failed",status);
        if (status2) {
                omapi_object_dereference(&hp,__FILE__,__LINE__);
                return NULL;
        }

        if ((status = dhcpctl_get_value(&result, hp, "hardware-address"))) {
                omapi_object_dereference(&hp,__FILE__,__LINE__);
                return NULL;
        }

        ret=ether_ntoa((struct ether_addr*)&result->value);

        omapi_object_dereference(&hp,__FILE__,__LINE__);

        return ret;
}


};

